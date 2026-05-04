//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// Diceware-style short words for memorable passphrases (local-only generation).
nonisolated enum PassphraseWordPool {

  nonisolated static let words: [String] = {
    // ~240 common-length tokens; avoids needing bundled files while remaining unpredictable when combined.
    let raw = """
      ablaze acorn agenda alpine anchor apple april atlas autum azure bacon badge ballad bamboo \
      beacon berry birch blaze blimp bloom bolt brass breeze brick bright brisk bronze brook \
      brush buffalo bundle butter camel canyon carol cedar chance cherry chilly cider cobalt \
      comet cosmic cradle cricket crystal current dagger dapper delta desert diesel dolphin \
      domain dragon drizzle eagle edison elder emerald engine fabric falcon fennel fever \
      flamingo flint forest formal fossil fountain galaxy garden garlic ginger glacier glitter \
      gondola griffin harvest helmet horizon humming iceberg igloo indoor invent ivory jasper \
      jigsaw jumbo juniper kennel kernel kindle lantern legend lotus lunar lyric maple marble \
      meteor midnight mimic monarch mosaic motion neon noble nordic oasis object ocean olive \
      orbit orchid paper paprika parchment pebble pegasus penguin phantom picnic pilot pioneer \
      pixel plaza polar prairie prism puzzle quartz quiver raptor raven relay ribbon rocket \
      rustic sailor satsuma saffron satellite savanna schema scooter season shadow shark shelter \
      shimmer signal silent silver skyline soda sonar sonic spark sphere spiral spruce squirrel \
      stencil summit sunset surfer swallow swift symbol tablet talon temple timber tonic torch \
      tower trail travel treble tropical tundra turbine twilight umbrella unicorn valley vector \
      velvet vendor vertex vintage violet vivid volcano voyage waffle wander warp winter wisdom \
      woodland wren zenith zipper zodiac absolve adjust admit advance agenda airborne album \
      almond ambient ancient anchor anthem apart arcade archive armor arrow aspect aurora axiom \
      badge balloon banquet barrier basket battery beacon bedrock beehive berries blossom \
      blueprint bracket brave breeze bridge bright brochure budget bumper bundle burrow camel \
      canyon cascade castle cattle census chamber channel chapter cheetah cherry cherry civic \
      cluster cobra compass concert coral cosmic cricket crystal cycle dagger dancer derby desert \
      diamond diesel dolphin domain draft dragon drift durable dynamic echo eddy elegant element \
      ember engine enjoy enrich episode equinox escape essence evening fabric falcon fantasy \
      fathom feather festival fiction fieldstone filament final finish flavor flex flight flour \
      foliage forever forum fossil fountain freeze frontier galaxy garment gentle glacier golden \
      graceful granite gravity guitar habitat harbor harvest helmet hero hidden hillside horizon \
      hybrid iceberg imagine impact indoor inferno inkjet island ivory jasmine journey jubilee \
      jungle justice kernel kinetic lagoon lantern latitude lattice legend liberty lightning \
      limestone lion lunar lyric magnetic mandarin maple marble maritime marker meadow melody \
      meteor midnight mimic mosaic motion mountain native nectar neon nightingale noble northern \
      notion oasis objective observe ocean official orange orchard orbit orchid outdoor ozone \
      pacific palette paper parade parsley pastel patrol pave pearl penguin picnic pilot pioneer \
      pixel plaza polar prairie prelude prism puzzle quartz quiet racing raptor raven recycle \
      relay ribbon ripple ritual rocket rustic safari sailor satellite scaffold season shadow \
      sherbet shimmer signal silent silver skyline soda sonar sonic sparkle spiral spruce squirrel \
      stadium stencil sterling stormy summit sunset surfer swallow swift symbol tablet talon \
      temple thunder timber tonic torch tornado tower trail transit travel treble tremor \
      tropical tumble tunnel tundra turbine twilight umbrella unicorn valley vector velvet vendor \
      vertex vintage violet vivid volcano voyage waffle wander warmth warp winter wisdom wooden \
      woodland woven wreath wren zenith zephyr zipper zodiac zoom
      """
    return raw
      .split(whereSeparator: { $0.isWhitespace })
      .map(String.init)
  }()

}
