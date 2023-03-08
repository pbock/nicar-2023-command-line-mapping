#!/bin/bash

cp data/tn_population_by_tract.csv inputs/
cp shapefiles/cb_2021_47_tract_500k.zip inputs/
unzip -o -d inputs/ inputs/cb_2021_47_tract_500k.zip

COMMANDS=(
  # Open the tracts shapefile and name the resulting layer "tracts"
  -i inputs/cb_2021_47_tract_500k.shp name=tracts
  # Open census data (without geometries!), name the resulting layer "pops" and
  # make field names easier to work with
  -i inputs/tn_population_by_tract.csv name=pops csv-field-names=long_geoid,name,population,_
  # Add a geoid field that we can join on. Since we haven't specified a target
  # layer, this command targets the most recent layer
  -each 'geoid=long_geoid.split("US")[1]'
  # Join the census data to the tracts shapefile
  -join source=pops target=tracts keys=GEOID,geoid
  # Calculate population density in square miles and its square root (which will
  # be used in visualisation)
  -each 'density=Math.floor(population / ALAND * (1609.34 ** 2)), density_sqrt=Math.sqrt(density)'
  # Simplify geometry
  -simplify 5%
  # Add a fill color
  -classify density_sqrt colors=Magma method=hybrid continuous invert classes=50
  # Project to Albers Equal Area
  -proj aea +lat_1=35.4 +lat_2=36.3 +pm=-86
  # Find the boundaries between counties and add a new layer (+) instead of
  # replacing the existing one
  -innerlines where='A.GEOID.slice(0, 5) != B.GEOID.slice(0, 5)' + name=county-boundaries
  # Style the tracts and county boundaries
  -style target=tracts fill=fill
  -style target=county-boundaries stroke='#000' stroke-opacity=0.3
  # Export to SVG
  -o outputs/map.svg target=tracts,county-boundaries width=960 height=960
)

node_modules/.bin/mapshaper "${COMMANDS[@]}"
