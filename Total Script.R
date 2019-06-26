####R Spatial and Maps Workshop####
#Last edit: 15:19 26/06/2019 by M Kerr#

##Hey, you bothered to download this? Well, thanks for following along at home!
##This R code will take you through a few different approaches to plotting maps, with some examples on how they might be used
##We will end up with a /very/ quick showcase of writing and visualising raster files in R
##Any questions you can email matthew.kerr@mq.edu.au and I will try to get back to you - but I am in no way an expert so fully expect me to have no idea

##Here are the packages that will be used in the workshop if you don't have them already:
install.packages("ggplot2") #Nice figures
install.packages("ggmap") #Nicer maps than 'maps'
install.packages("gganimate") #Animated figures
install.packages("gifski") #Animated figure rendering
install.packages("robis") #OBIS client
install.packages("raster") #Raster file manipulation
install.packages("rgdal") #Geospatial Data Abstraction Library
install.packages("igraph") #Network Analysis/Visualisation

##Let's start by talking about maps!
#R has many powerful tools for plotting and generating maps at all spatial scales.
#We are not going to cover the maps package at all here, instead we are going to jump straight into some ggplot:
library(ggplot2)
library(ggmap)

##NOTE: for some of the ggmap functions you will need to have a Google API
##I have attached mine here, but it will cease to work for anyone other than me after 16:30 27th June 2019
register_google(key = "AIzaSyCKUVR3797qvvzi_tPj0-ep8b6U6nLm8DA")
##If you want to continue to use the full functionality of ggmap, get one yourself! It's free for at least a year if you have a google account.

##So let's go over some basics
?ggplot #This is how ggplot plots cool figures
?qplot #This is a quick way of doing a ggplot figure if you are too scared of using ggplot
?theme_bw #This is a quick way of making a ggplot figure looking nice
?map_data #This is the "normal" ggplot2 way of getting maps
?get_map #This is the "basic" ggmap command and will allow us to pull geographic data from google

##So let's start with continental scale data!
#Let's quickly download some occurence data, after all I am a biologist:
library(robis)

#The robis package allows us to directly pull data from OBIS (Ocean Biogeographic Information System)
#There are 2005 humpback whale records in Australia (area 8) which is manageable:
whales = occurrence(scientificname = "Megaptera novaeangliae", areaid = 8)

#Let's see how this data looks
w = qplot(data = whales, x = decimalLongitude, y = decimalLatitude) + theme_bw() #qplot defaults to a scatter plot
w #Note that qplot is very similar to base R plotting, but looks way better already. Everyone should use it!

#Not bad! This data looks way cleaner than my own ("Molluscs are hard!" - No one cares, Matt get over it.)
#We could make this look nicer though
#Let's start by adding an outline of Australia
aus = map_data(map = "world2", region = "Australia")

#This stores the map as a polygon, so let's quickly plot it using normal ggplot syntax
  #ggplot() opens a new plot for you to add stuff to
  #geom_polygon() tells ggplot what type of thing you will be plotting (polygon) and what it should look like (aes)
      #data tells ggplot what data (data frames only) it needs
      #aes() tells ggplot what the x and y values are, and if there is anything that needs to be scaled
  #theme_bw() tells ggplot what parameters it will use to plot
  #Other geoms can be used for other types of plot! A few common examples are geom_point(), geom_line() and geom_bar()
m = ggplot() + geom_polygon(data = aus, aes(x = long, y = lat)) + theme_bw()
m

#No! This looks awful! ("I apologise for making you see that")
#ggplot has the tendancy to plot things in its own order - we need to specify the "group" within the aes() part of our ggplot
#For this type of map it is just called "group"
m = ggplot() + geom_polygon(data = aus, aes(x = long, y = lat, group = group)) + theme_bw()
m

##Now let's add in our whale data
w + 
  geom_polygon(data = aus, aes(x = long, y = lat, group = group), fill = "lightgrey", colour = "black", alpha = 0.4) + 
  theme_bw() + coord_fixed(ratio = 1) + ylim(c(-45, -10))

#Always make sure you use this when you are oulling map data directly from a package
#I have also been cheeky and added a coord_fixed() and ylim() command
#Both of this just make the plot a bit more vidually pleasing for now BUT be aware that this gives a different projection than you might want
#Remember the Earth isn't flat...

#So far all we have done is just make a slightly prettier map than base R could do
#Let's just explore a few other ways of visualising this kind of data
#Let's move everything into proper ggplot format first and use the geom_bin_2d command
#This plots a 2d histogram as a density plot
w = ggplot(whales, aes(x = decimalLongitude, y = decimalLatitude)) + 
  geom_bin2d(bins = 50) +
  geom_polygon(data = aus, aes(x = long, y = lat, group = group), fill = "lightgrey", colour = "black", alpha = 0.4) + 
  theme_bw() + coord_fixed(ratio = 1) + ylim(c(-45, -10))
w
#Now we have an idea of how many whales people are seeing across Australia! Kinda. ("Not as cool as 500,000 shells")
#For people new to ggplot, geoms specify the type of plot you are wanting. You can specify this in qplot using 'geom = "bin2d"' if you want to change it.

#We can save this using the super easy ggsave function
ggsave(filename = "Figures/my_map.jpg") # ggsave always grabs the last plot you made

#Another way of looking this type of data is in countours. We can use the "kinda-geom" stat_density_2d to give us "hotspots" of whale occurences
ggplot(whales, aes(x = decimalLongitude, y = decimalLatitude)) + 
  stat_density_2d(aes(fill = ..level..), geom = "polygon") + geom_polygon(data = aus, aes(x = long, y = lat, group = group), fill = "lightgrey", colour = "black", alpha = 0.4) + 
  theme_bw() + coord_fixed(ratio = 1) + ylim(c(-45, -10))
#Radical! This is obviously more useful for more continuous data. We will get into this later!

##Now let's move onto a small scale, and for this we are going to be using ggmap
#Let's start by playing around with the base ggmap function and keep looking at our whale data

country = get_map(location = c(134.5, -26), zoom = 4)
ggmap(country) + 
  geom_point(data = whales, aes(x = decimalLongitude, y = decimalLatitude))
#It's important to note that we don't need to specify the coord_fixed here as ggmap automatically scales it for us

#Hey look it's Australia! But that's super ugly, so let's focus on small scales
#I use this type of map to track hikes and runs, but they have loads of cool uses
#For this we are going to be using some of my personal data that I am gracious enough to share ("I am so nice please fund my research")
#This is data that I downloaded off my google maps profile - if you want your own it's super easy to get and use. Ask me at the end if you want to know more!
  #A note on data privacy - obviously I have stripped the file of anything that could be used to ID me.
  #If you do use your own google location data I would of course suggest not sharing it so openly!
  #As a result of only sharing a short bit of data, I have not provided to ode to actually extract this from the file google gives you. If you want it, ask!


#This is a day I did in Melbourne this time last year during a short holiday to see some art
melb = read.csv("Data/museum_trip.csv")

#I've given you the data for roughly 9 hours of the day, just so you can't work out where my hotel was

#Let's see what the path looks like:
qplot(data = melb, x = lon, y = lat, geom = "path") + theme_bw() #Note that google (and therefore ggmap) uses "lon" and not "long"
#The geom "path" is a line that connects points in the order they appear within a group

#Let's also just mark the start and end points
qplot(data = melb, x = lon, y = lat, geom = "path") + 
  theme_bw() + 
  geom_point(data = melb[1,], aes(x = lon, y = lat), size = 3) + 
  geom_point(data = melb[358,], aes(x = lon, y = lat), size = 3)

#Let's centre a google map on my mean location
#The "zoom" function allows us to see stuff at the road/building scale
#15 is probably zoomed enough...
map.centre = get_map(location = c(mean(melb$lon),mean(melb$lat)), source = "google", zoom = 15, maptype = "terrain")

#let's make sure this looks okay! I'll change the colour to red so it is easier to see
ggmap(map.centre) + 
  geom_path(data = melb, aes(x = lon, y = lat), size = 2, colour = "red")

#We could still do to zoom in a bit further, but there is an easier way rather than having to guess the zoom: bounding boxes!
#ggmap has a handy function for making a bounding box for you:
melb.box = make_bbox(lon = melb$lon, lat = melb$lat, f = 0.005) #f specifices how much edge you want your box to have
melb.box

#Now let's try this all again:
map.centre = get_map(location = melb.box, source = "google", zoom = 15, maptype = "roadmap")

ggmap(map.centre) + 
  geom_path(data = melb, aes(x = lon, y = lat), size = 1, colour = "red") #You will notice this map is way less busy. Thats due to how bounding boxes are downloaded! Some times you won't be able to use a bounding box for specific places


#This is a bit zoomed in for my liking, but I will leave it for now
#Now what is missing from this map? Well for a start it doesn't tell us anything
#I want to know how long this all took me, so I am going to add in a time aspect
#geom_path allows us to automatically scale the colours of the path to time/elevation/depth or whatever it may be
#Melbourne is almost as flat as Cambridge, so let's scale time:

#Here I am saving the plot as an object. I would recommend doing this, ggplot commands can get quite hefty and this saves a lot of time.
#You can also do something like p + geom_path() to save time in the future, as you will see shortly
p = ggmap(map.centre) + 
  geom_path(data = melb, aes(x = lon, y = lat, colour = time), size = 2, lineend = "round") + 
  scale_color_gradientn(colours = rainbow(7))
p
#Three things to note here:
  #I have added colour into the aes() part of ggplot. Adding it here rather than adding it to main command will automatically scale that aspect to the value provided
  #I have added a new command: scale_color_gradient. This allows us to change how we want it to scale. I am using rainbow for visual clarity, but there are many way better ones to use for real figures
  #I have changed the lineend within the geom_path to round. Just makes it look a bit nicer

#So now we can see my day as I walked around finding bars
#Just for fun, let's animate this - I know this will be a question later!
library(gganimate)
library(gifski)
#This will take a while as it renders. Just spend that time getting another cup of tea - you'll thank me!
p + transition_reveal(along = time)

#We can save this in a similar way using anim_save
anim_save("Figures/my_trip.gif") #Again, this will grab the last thing you made

#We may only want to know my position at one time though, so we can change this up:
a = ggmap(map.centre) + 
  geom_point(data = melb, aes(x = lon, y = lat), size = 2) + transition_reveal(along = time, keep_last = F)
a

#This may be more useful to any type of movement data you want to show
#I personally use these to keep track of hikes/runs that I do, so even if you don't care about anything else you should do this just for fun!
#Just please if you delete all your google location data, keep a backup. It's really cool and useful!

##So far we have made two different types of map. To finish the main part of the workshop, I will briefly talk about raster files in R
#Raster files are ways of storing spatial data as gridded data - many of you will have used these for abiotic variables
#The density plots we did earlier are an example of raster data as they are attached to coordinates
library(raster)
library(rgdal)

#Normally you will be loading raster information from a file, but we are going to make one from scratch to show how different bits of the raster work
r = raster(ncol = 10, nrow = 10, xmn = 1, xmx = 10, ymn = 1, ymx = 10)
#Here we have made a very basic raster file - we have a 10x10 grid that goes from 1-10 both in latitude and longitude
#Let's inspect it so you believe me
r

#Here we have a bunch of information, but your boy is gonna break it down:
  #Dimensions are what we specified earlier
  #Resolution is how much lat/lon wach square represents
  #Extent is what area this covers

#This file is empty though, so we can fill it with garbage for now
values(r) = rnorm(100, mean = 100, sd = 25) #Just generating some random numbers

#We can visualise this in a plot, but to use ggplot it has to be in a data frame:
r.df = as.data.frame(r, xy = T)
ggplot() + geom_raster(data = r.df, aes(x, y, fill = layer)) + theme_minimal()

#Wow! How useful!
#The raster package comes with an example file for us to play with too:
f.ex = system.file("external/test.grd", package="raster") #In real life you won't need to call system.file - you will just need to use raster() with your own file
r.ex = raster(f.ex)

#Let's see:
r.ex
r.ex.df = as.data.frame(r.ex, xy = T)
ggplot() + geom_raster(data = r.ex.df, aes(x, y, fill = test)) + theme_minimal()
#You can of course use base plot for this without any special commands, but I expect you not to. If you do want to, use plot(r.ex)

#Very cool! We can extract individual points using the raster file too:
#Let's do some quick functions that you could do in other programs:

##Shortest distance to a non-NA point
d = distance(r.ex)
d.df = as.data.frame(d, xy = T)
ggplot() + geom_raster(data = d.df, aes(x, y, fill = layer)) + theme_minimal()
#We can find an individual points distance this way too:
d[1,1] #Distance of the upper left point

##Groups of connected cells
library(igraph) #We need this now

d.cl = clump(r.ex)
d.cl.df = as.data.frame(d.cl, xy = T)
ggplot() + geom_raster(data = d.cl.df, aes(x, y, fill = clumps)) + theme_minimal()
#Note that this data isn't clumped, so it will look a bit odd. We can do this with the whale data though, maybe try that yourself!

###There are obviously way more things to do with raster files, including stacking and predicting cell values - these are commonly used for modelling purposes
###If I went into these I could be here all day - but feel free to ask and I will try my best!