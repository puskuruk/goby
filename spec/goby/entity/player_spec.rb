require 'goby'

RSpec.describe Player do

  # Constructs a map in the shape of a plus sign.
  let!(:map) { Map.new(tiles: [[Tile.new(passable: false), Tile.new, Tile.new(passable: false)],
                               [Tile.new, Tile.new, Tile.new(monsters: [Monster.new(battle_commands: [Attack.new(success_rate: 0)])])],
                               [Tile.new(passable: false), Tile.new, Tile.new(passable: false)]],
                       regen_location: C[1, 1]) }
  let!(:center) { map.regen_location }
  let!(:passable) { Tile::DEFAULT_PASSABLE }
  let!(:impassable) { Tile::DEFAULT_IMPASSABLE }

  let!(:dude) { Player.new(stats: {attack: 10, agility: 10000, map_hp: 2000}, gold: 10,
                           battle_commands: [Attack.new(strength: 20), Escape.new, Use.new],
                           map: map, location: center) }
  let!(:slime) { Monster.new(battle_commands: [Attack.new(success_rate: 0)],
                             gold: 5000, treasures: [C[Item.new, 1]]) }
  let!(:newb) { Player.new(battle_commands: [Attack.new(success_rate: 0)],
                           gold: 50, map: map, location: center) }
  let!(:dragon) { Monster.new(stats: {attack: 50, agility: 10000},
                              battle_commands: [Attack.new(strength: 50)]) }
  let!(:chest_map) { Map.new(name: "Chest Map",
                             tiles: [[Tile.new(events: [Chest.new(gold: 5)]), Tile.new(events: [Chest.new(gold: 5)])]],
                             regen_location: C[0, 0]) }

  context "constructor" do
    it "has the correct default parameters" do
      player = Player.new
      expect(player.name).to eq "Player"
      expect(player.stats[:max_hp]).to eq 1
      expect(player.stats[:hp]).to eq 1
      expect(player.stats[:attack]).to eq 1
      expect(player.stats[:defense]).to eq 1
      expect(player.stats[:agility]).to eq 1
      expect(player.inventory).to eq Array.new
      expect(player.gold).to eq 0
      expect(player.outfit).to eq Hash.new
      expect(player.battle_commands).to eq Array.new
      expect(player.map).to eq Player::DEFAULT_MAP
      expect(player.location).to eq Player::DEFAULT_LOCATION
    end

    it "correctly assigns custom parameters" do
      hero = Player.new(name: "Hero",
                        stats: {max_hp: 50,
                                hp: 35,
                                attack: 12,
                                defense: 4,
                                agility: 9},
                        inventory: [C[Item.new, 1]],
                        gold: 10,
                        outfit: {weapon: Weapon.new(
                            attack: Attack.new,
                            stat_change: {attack: 3, defense: 1}),
                                 helmet: Helmet.new(
                                     stat_change: {attack: 1, defense: 5})},
                        battle_commands: [
                            BattleCommand.new(name: "Yell"),
                            BattleCommand.new(name: "Run")
                        ],
                        map: map,
                        location: C[1, 1])
      expect(hero.name).to eq "Hero"
      expect(hero.stats[:max_hp]).to eq 50
      expect(hero.stats[:hp]).to eq 35
      expect(hero.stats[:attack]).to eq 16
      expect(hero.stats[:defense]).to eq 10
      expect(hero.stats[:agility]).to eq 9
      expect(hero.inventory).to eq [C[Item.new, 1]]
      expect(hero.gold).to eq 10
      expect(hero.outfit[:weapon]).to eq Weapon.new
      expect(hero.outfit[:helmet]).to eq Helmet.new
      expect(hero.battle_commands).to eq [
                                             Attack.new,
                                             BattleCommand.new(name: "Run"),
                                             BattleCommand.new(name: "Yell")
                                         ]
      expect(hero.map).to eq map
      expect(hero.location).to eq C[1, 1]
    end

    context "places the player in the default map & location" do
      it "receives the nil map" do
        player = Player.new(location: C[2, 4])
        expect(player.map).to eq Player::DEFAULT_MAP
        expect(player.location).to eq Player::DEFAULT_LOCATION
      end

      it "receives the nil location" do
        player = Player.new(map: Map.new)
        expect(player.map).to eq Player::DEFAULT_MAP
        expect(player.location).to eq Player::DEFAULT_LOCATION
      end

      it "receives an out-of-bounds location" do
        player = Player.new(map: Map.new, location: C[0, 1])
        expect(player.map).to eq Player::DEFAULT_MAP
        expect(player.location).to eq Player::DEFAULT_LOCATION
      end

      it "receives an impassable location" do
        player = Player.new(map: Map.new(tiles: [[Tile.new(passable: false)]]),
                            location: C[0, 0])
        expect(player.map).to eq Player::DEFAULT_MAP
        expect(player.location).to eq Player::DEFAULT_LOCATION
      end
    end

  end

  context "choose attack" do
    it "should choose the correct attack based on the input" do
      charge = BattleCommand.new(name: "Charge")
      zap = BattleCommand.new(name: "Zap")
      player = Player.new(battle_commands: [charge, zap])

      # RSpec input example. Also see spec_helper.rb for __stdin method.
      __stdin("kick\n", "zap\n") do
        expect(player.choose_attack.name).to eq "Zap"
      end
    end
  end

  context "choose item and on whom" do
    let!(:banana) { Item.new(name: "Banana") }
    let!(:axe) { Item.new(name: "Axe") }
    let!(:entity) { Player.new(inventory: [C[banana, 1],
                                           C[axe, 3]]) }
    let!(:enemy) { Entity.new(name: "Enemy") }

    it "should return correct values based on the input" do
      # RSpec input example. Also see spec_helper.rb for __stdin method.
      __stdin("goulash\n", "axe\n", "bill\n", "enemy\n") do
        pair = entity.choose_item_and_on_whom(enemy)
        expect(pair.first.name).to eq "Axe"
        expect(pair.second.name).to eq "Enemy"
      end
    end

    context "should return nil on appropriate input" do
      it "for item" do
        # RSpec input example. Also see spec_helper.rb for __stdin method.
        __stdin("goulash\n", "pass\n") do
          pair = entity.choose_item_and_on_whom(enemy)
          expect(pair).to be_nil
        end
      end

      it "for whom" do
        # RSpec input example. Also see spec_helper.rb for __stdin method.
        __stdin("banana\n", "bill\n", "pass\n") do
          pair = entity.choose_item_and_on_whom(enemy)
          expect(pair).to be_nil
        end
      end
    end
  end

  context "move to" do
    it "correctly moves the player to a passable tile" do
      dude.move_to(C[2, 1])
      expect(dude.map).to eq map
      expect(dude.location).to eq C[2, 1]
    end

    it "prevents the player from moving on an impassable tile" do
      dude.move_to(C[2, 2])
      expect(dude.map).to eq map
      expect(dude.location).to eq center
    end

    it "prevents the player from moving on a nonexistent tile" do
      dude.move_to(C[3, 3])
      expect(dude.map).to eq map
      expect(dude.location).to eq center
    end

    it "saves the information from previous maps" do
      dude.move_to(C[0, 0], chest_map)
      interpret_command("open", dude)
      expect(dude.gold).to eq 15
      dude.move_to(C[1, 1], Map.new)
      dude.move_to(C[0, 0], Map.new(name: "Chest Map"))
      interpret_command("open", dude)
      expect(dude.gold).to eq 15
      dude.move_right
      interpret_command("open", dude)
      expect(dude.gold).to eq 20
    end
  end

  context "move up" do
    it "correctly moves the player to a passable tile" do
      dude.move_up
      expect(dude.map).to eq map
      expect(dude.location).to eq C[0, 1]
    end

    it "prevents the player from moving on a nonexistent tile" do
      dude.move_up; dude.move_up
      expect(dude.map).to eq map
      expect(dude.location).to eq C[0, 1]
    end
  end

  context "move right" do
    it "correctly moves the player to a passable tile" do
      20.times do
        __stdin("Attack\n") do
          dude.move_right
          expect(dude.map).to eq map
          expect(dude.location).to eq C[1, 2]
          dude.move_left
        end
      end
    end

    it "prevents the player from moving on a nonexistent tile" do
      __stdin("Attack\n") do
        dude.move_right; dude.move_right
        expect(dude.map).to eq map
        expect(dude.location).to eq C[1, 2]
      end
    end
  end

  context "move down" do
    it "correctly moves the player to a passable tile" do
      dude.move_down
      expect(dude.map).to eq map
      expect(dude.location).to eq C[2, 1]
    end

    it "prevents the player from moving on a nonexistent tile" do
      dude.move_down; dude.move_down
      expect(dude.map).to eq map
      expect(dude.location).to eq C[2, 1]
    end
  end

  context "move left" do
    it "correctly moves the player to a passable tile" do
      dude.move_left
      expect(dude.map).to eq map
      expect(dude.location).to eq C[1, 0]
    end

    it "prevents the player from moving on a nonexistent tile" do
      dude.move_left; dude.move_left
      expect(dude.map).to eq map
      expect(dude.location).to eq C[1, 0]
    end
  end

  context "update map" do
    let!(:line_map) { Map.new(tiles: [[Tile.new, Tile.new, Tile.new, Tile.new]]) }
    let!(:player) { Player.new(map: line_map, location: C[0, 0]) }

    it "uses default argument to update tiles" do
      player.update_map
      expect(line_map.tiles[0][3].seen).to eq false
    end

    it "uses given argument to update tiles" do
      player.update_map(C[0, 2])
      expect(line_map.tiles[0][3].seen).to eq true
    end
  end

  context "print map" do
    it "should display as appropriate" do
      edge_row = "#{impassable} #{passable} #{impassable} \n"
      middle_row = "#{passable} ¶ #{passable} \n"

      expect { dude.print_map }.to output(
                                       "   Map\n\n"\
        "  #{edge_row}"\
        "  #{middle_row}"\
        "  #{edge_row}"\
        "\n"\
        "   ¶ - #{dude.name}'s\n"\
        "       location\n\n"
                                   ).to_stdout
    end
  end

  context "print minimap" do
    it "should display as appropriate" do
      edge_row = "#{impassable} #{passable} #{impassable} \n"
      middle_row = "#{passable} ¶ #{passable} \n"

      expect { dude.print_minimap }.to output(
                                           "\n"\
        "          #{edge_row}"\
        "          #{middle_row}"\
        "          #{edge_row}"\
        "          \n"
                                       ).to_stdout
    end
  end

  context "print tile" do
    it "should display the marker on the player's location" do
      expect { dude.print_tile(dude.location) }.to output("¶ ").to_stdout
    end

    it "should display the graphic of the tile elsewhere" do
      expect { dude.print_tile(C[0, 0]) }.to output(
                                                 "#{impassable} "
                                             ).to_stdout
      expect { dude.print_tile(C[0, 1]) }.to output(
                                                 "#{passable} "
                                             ).to_stdout
    end
  end

  # Fighter specific specs

  context "fighter" do
    it "should be a fighter" do
      expect(dude.class.included_modules.include?(Fighter)).to be true
    end
  end

  context "battle" do
    it "should allow the player to win in this example" do
      __stdin("attack\n") do
        dude.battle(slime)
      end
      expect(dude.inventory.size).to eq 1
    end

    it "should allow the player to escape in this example" do
      # Could theoretically fail, but with very low probability.
      __stdin("escape\nescape\nescape\n") do
        dude.battle(slime)
        expect(dude.gold).to eq 10
      end
    end

    it "should allow the monster to win in this example" do
      __stdin("attack\n") do
        newb.battle(dragon)
      end
      # Newb should die and go to respawn location.
      expect(newb.gold).to eq 25
      expect(newb.location).to eq C[1, 1]
    end

    it "should allow the stronger player to win as the attacker" do
      __stdin("attack\nattack\n") do
        dude.battle(newb)
      end
      # Weaker Player should die and go to respawn location.
      expect(newb.gold).to eq 25
      expect(newb.location).to eq C[1, 1]
      # Stronger Player should get weaker Players gold
      expect(dude.gold).to eq (35)
    end

    it "should allow the stronger player to win as the defender" do
      __stdin("attack\nattack\n") do
        newb.battle(dude)
      end
      # Weaker Player should die and go to respawn location.
      expect(newb.gold).to eq 25
      expect(newb.location).to eq C[1, 1]
      # Stronger Player should get weaker Players gold
      expect(dude.gold).to eq (35)
    end

  end

  context "die" do
    it "moves the player back to the map's regen location" do
      dude.move_down
      expect(dude.location).to eq C[2, 1]
      dude.die
      expect(dude.location).to eq map.regen_location
    end

    it "recovers the player's HP to max" do
      dude.set_stats(hp: 0)
      dude.die
      expect(dude.stats[:hp]).to eq dude.stats[:max_hp]
    end
  end

  context "sample gold" do
    it "reduces the player's gold by half" do
      dude.set_gold(10)
      dude.sample_gold
      expect(dude.gold).to eq 5
    end

    it "returns the amount of gold the player has lost" do
      dude.set_gold(10)
      expect(dude.sample_gold).to eq 5
    end
  end

  context "sample treasures" do
    it "returns nil to indicate the player has lost no treasures" do
      expect(dude.sample_treasures).to be_nil
    end
  end
end
