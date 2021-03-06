# This is an example of how to create a Map. You can
# define the name, where to respawn, and the 2D display of
# the Map - each point is referred to as a Tile.
class Farm < Map
  def initialize
    super(name: "Farm", regen_location: C[2,2])

    # Define the main tiles on this map.
    grass = Tile.new(description: "You are standing on some grass.")

    # Fill the map with "grass."
    @tiles = Array.new(5) { Array.new(5) { grass.clone } }

  end
end
