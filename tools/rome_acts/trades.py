"""Work, the market, dice and the money changer's table (docs/rome-activities-plan.md, 3.1-3.4, 3.13):
what you can do with the people you stop in the street, by their trade. JOBS maps a job (people.json)
to the thing to ask them ("Ask for a day's work", "Buy something", "Play at dice"...) and its scene;
a scene "<id>_<age>" is used in that age if there is one, else "<id>".
"""

from .common import (say, ask, opt, end, label, go, rite, hold, still, timing, typing, pick, gain, pay, wage, iff, play,
                     scene, hour, errand)

S = {}

# ---------- a day's work ----------

S["work_baker_early"] = scene(
    "A day at the mill", "A house in the city, 201 BC",
    say("There are no bakers' shops yet: the pistor pounds and grinds the grain for households. Your employer's slaves are at the war."),
    timing("Pound the grain in the mortar, on the beat.", hits=4, speed=1.0, zone=0.2, miss="The pestle skids.",
           good=["Good.", "Good.", "Nearly there.", "Done."]),
    wage(2, per=1, say="He pays you in coin, and a loaf."),
    gain(give="a loaf"),
    end("Honest work for honest pay. He'll have you again."),
)

S["work_baker"] = scene(
    "A day at the bakery", "The bakery",
    say("A donkey turns the millstone in the back, blindfolded so it won't get dizzy. You knead, load the oven, and stamp each loaf with the baker's mark."),
    timing("Load the loaves and pull them out at the right moment.", hits=4, speed=1.1, zone=0.18,
           miss="Burnt at the edge.", good=["Golden.", "Golden.", "Good.", "The last tray."]),
    ask("The baker says: cut the dough a little short on each loaf. \"Everyone does. The aedile's never here.\"",
        opt("Cut them short", coin=2, fides=-1, say="Eight loaves in a hundred are dough you never used. The baker grins.",
            ledger="Baked short-weight loaves.", ledger_key="short_weight"),
        opt("Honest weight", say="The baker shrugs. \"Your loss.\""),
    ),
    wage(2, per=1, say="He pays you at the end of the day."),
    end("You smell of the oven for two days. Half the Subura will eat what you made."),
)

S["work_baker_late"] = scene(
    "A day at the bakery", "The bakery, AD 384",
    say("The baker was born a baker and will die one: the law binds his family to the ovens, to bake the state's bread. His son ran off to be a priest and was brought back."),
    timing("Load and pull the loaves.", hits=4, speed=1.1, zone=0.18, miss="Burnt.", good=["Good.", "Good.", "Good.", "Done."]),
    ask("\"Don't come back,\" he says quietly. \"If you work here too long they'll put your name on the roll. Then you're a baker forever.\"",
        opt("Take your pay and go", then="pay"),
        opt("Say you'll come back", say="He looks at you as if you'd said you'd like to be buried alive.", then="pay"),
    ),
    label("pay"),
    wage(2, per=1),
    end("The state's bread is free for the people, and it costs the bakers everything."),
)

S["work_baker_fall"] = scene(
    "The bakery", "The bakery, AD 552",
    say("There is no flour. The mills on the river were smashed in the siege and the grain doesn't come. The oven is cold."),
    end("The baker's family sits in the doorway. They have nothing to sell and nothing to do."),
)

S["work_fuller"] = scene(
    "A day at the fuller's", "The fullery",
    say("Cloth is cleaned in vats of water and stale urine: the fuller collects it in pots at street corners. You tread the cloth all day, standing in it."),
    timing("Tread the cloth in the vat, in rhythm with the man beside you.", hits=4, speed=1.0, zone=0.2,
           miss="You slip. He catches your arm.", good=["Stamp.", "Stamp.", "Stamp.", "Done."]),
    hold("Hang it over the sulphur frame to whiten it. Hold your breath.", secs=3.0, done="Your eyes stream."),
    iff({"score": 3}, "good"),
    say("You've scorched the purple border of a senator's toga. The fuller goes white. He'll have to pay for it."),
    gain(say="He docks your pay.", fides=-1),
    go("end"),
    label("good"),
    wage(2, per=1, say="He pays you, and tells you to wash."),
    label("end"),
    end("Nobody likes the smell of a fuller's. Everybody likes a clean toga."),
)

S["work_fuller_empire"] = dict(S["work_fuller"], steps=S["work_fuller"]["steps"][:-1] + [
    end("The Emperor Vespasian taxed the urine they collect. When his son complained, he held a coin under his nose: \"Does it smell?\"")])

S["work_fuller_heroic"] = scene(
    "A day at the fuller's", "The fullery, 280 BC",
    say("The fuller cleans the soldiers' woollen cloaks before they march. Urine and water in the vat, and your feet."),
    timing("Tread the cloth, in rhythm.", hits=3, speed=0.9, zone=0.22, miss="You slip.", good=["Stamp.", "Stamp.", "Done."]),
    wage(2, per=1, say="He pays you, and tells you the cloaks you trod will go to fight Pyrrhus."),
    end("Clean cloaks for the legion. Even the fuller serves the Republic."),
)

S["work_porter"] = scene(
    "A load to carry", "The river port",
    say("A merchant needs a sack of grain taken from the Emporium up to a shop in the Subura. No map: \"past the Circus, up the Vicus Tuscus, through the Forum, and up the Argiletum.\""),
    pick("Which way is the Forum from the Circus Maximus?", ["North, up the Vicus Tuscus", "South, along the river", "West, over the bridge"], 0,
         yes="Right: up the Vicus Tuscus between the Palatine and the Capitol.", no="North: up the Vicus Tuscus. You find it, late."),
    timing("Up the steps of the Argiletum with the sack on your shoulder: keep your balance.", hits=3, speed=1.2, zone=0.2,
           miss="You stagger. The sack nearly goes.", good=["Steady.", "Steady.", "There."]),
    wage(1, per=1, say="The shopkeeper pays you at his door."),
    end("Rome is carried on men's backs, up and down its hills, all day."),
)

S["work_water"] = scene(
    "Carrying water", "The street fountain",
    say("The aqueducts run to the street fountains, not to the upper floors. A woman on the fifth floor needs two jars a day and can't carry them."),
    timing("Fill the jars at the fountain spout without overflowing.", hits=2, speed=1.0, zone=0.22, miss="It slops over.",
           good=["Full.", "Full."]),
    hold("Up five flights of wooden stairs. Don't spill.", secs=4.0, done="Fifth floor."),
    wage(1, per=1, say="She pays you in coins she keeps in a jar."),
    end("The rich have water piped into their houses from the aqueducts. The poor have stairs."),
)

S["work_water_fall"] = scene(
    "Carrying water", "The river, AD 552",
    say("The aqueducts were cut in the first siege, eighteen years ago. The fountains are dry. Water comes up from the Tiber, brown."),
    hold("Carry the jar up from the river.", secs=4.0, done="You set it down. It has sand in it."),
    wage(1, say="A family in a ruin pays you with a piece of bread."),
    end("The fevers come with the river water. Everyone knows. There is no other water."),
)

S["work_scribe_republic"] = scene(
    "Copying", "The bookseller's shop, about 50 BC",
    say("The bookseller's slaves copy books by dictation, a dozen at a time. He needs another hand today."),
    typing("How long, Catiline, will you abuse our patience?", secs=25),
    ask("After hours, the bookseller brings out something else: Catullus's verses on Caesar and his friend Mamurra. Filthy, and very popular.",
        opt("Copy them for extra", coin=3, say="Caesar knows about them. He invited Catullus to dinner anyway.",
            ledger="Copied the lampoons against Caesar.", ledger_key="lampoon"),
        opt("Just the Cicero", say="\"Suit yourself,\" says the bookseller."),
    ),
    wage(2, per=1, say="He pays you for the day."),
    end("Rome reads everything: speeches, poems, scandal, the Senate's minutes posted on a board. Words move faster than soldiers."),
)

S["work_scribe_empire"] = scene(
    "Copying", "The bookseller's shop, about AD 150",
    say("Near the Forum of Peace are the booksellers: the new Virgils, the new Martials, cheap copies for the provinces."),
    typing("Remember, Roman, to rule the peoples with your power.", secs=25),
    wage(2, per=1, say="He pays you, and says the provinces buy Virgil by the crate."),
    end("Every schoolboy from Britain to Syria learns Virgil by heart. The poem of Rome is more Roman now than Rome."),
)

S["work_scribe_late"] = scene(
    "Copying", "The clerk's office, AD 384",
    say("The Prefect Symmachus's plea to the Emperor, for the Altar of Victory, is being copied to send to friends."),
    typing("Not by one road alone can one reach so great a mystery.", secs=25),
    ask("A clerk from the bishop's household offers you money to copy something for him too: the bishop of Milan's reply.",
        opt("Copy both", coin=2, say="You copy both. Symmachus's is better written. Ambrose's wins."),
        opt("Just Symmachus's", say="The clerk goes to someone else."),
    ),
    wage(2, per=1),
    end("The Altar stays out. The argument will be copied for a thousand years."),
)

S["work_cutter"] = scene(
    "Cutting an epitaph", "The mason's yard",
    say("A family wants an epitaph cut for their son, in the usual abbreviations. The mason draws the letters in red; you cut."),
    pick("It begins with the letters D M. What do they stand for?", ["To the spirits of the dead (Dis Manibus)", "Dear mother", "The day of death"], 0,
         yes="D M: to the spirits of the dead.", no="D M: Dis Manibus, to the spirits of the dead."),
    pick("After his name: V A XIX. What is that?", ["He lived nineteen years (vixit annos)", "Vale, nineteen times", "He was a veteran of the 19th"], 0,
         yes="Vixit annos: he lived nineteen years.", no="Vixit annos XIX: he lived nineteen years."),
    pick("At the end: S T T L.", ["May the earth lie light on you", "Sacred to the Lares", "Here lies the ashes"], 0,
         yes="Sit tibi terra levis.", no="Sit tibi terra levis: may the earth lie light on you."),
    hold("Cut the letters.", secs=3.5, done="The chips fly. The letters are clean."),
    wage(2, per=1, say="The mason pays you."),
    end("His name will be read by strangers for two thousand years. His parents paid for that."),
)

S["work_cutter_republic"] = scene(
    "Cutting an epitaph", "The mason's yard, about 50 BC",
    say("A freedman's family wants an epitaph, in the old plain style."),
    pick("It ends H S E. What is that?", ["Here he lies (hic situs est)", "His sons erected it", "Hail, spirit, eternally"], 0,
         yes="Hic situs est: here he lies.", no="Hic situs est: here he lies."),
    hold("Cut the letters.", secs=3.0, done="Clean."),
    wage(2, per=1),
    end("The freedman was a slave from Syria. On the stone he is a Roman citizen, forever."),
)

S["work_cutter_late"] = scene(
    "Cutting an epitaph", "The mason's yard, AD 384",
    say("A Christian family wants their daughter's stone for the catacomb: a dove, and a few words."),
    pick("How should it end?", ["IN PACE: in peace", "S T T L: may the earth lie light", "D M: to the spirits of the dead"], 0,
         yes="In peace. The dead are not spirits below now; they are sleeping, waiting.",
         no="In pace. The old formulas are for the old gods."),
    hold("Cut the dove and the letters.", secs=3.0, done="The dove is a little crooked. They don't mind."),
    wage(2, per=1),
    end("The letters are worse cut than they were. There is more hope in them."),
)

S["work_cutter_fall"] = scene(
    "Cutting a stone", "The mason's yard, AD 552",
    say("There is no new marble. The mason cuts old stones smaller: a pagan epitaph turned over, a temple's cornice sawn into slabs."),
    hold("Saw the old stone.", secs=4.0, done="On the underside: D M, and a name, and XIX. Someone's son."),
    wage(1),
    end("Rome is being built out of Rome."),
)

S["work_fish"] = scene(
    "Selling the catch", "The fish stall",
    say("The fishwife has more fish than she can sell before the noon heat turns them. \"Take a basket to the steps and sell it.\""),
    play("haggle", win="sold", lose="spoiled", buying=False, item="a basket of fish", value=4),
    label("sold"),
    gain(fides=0),
    end("You bring her the money. She gives you a fish for yourself."),
    label("spoiled"),
    end("By noon they stink. She throws them to the dogs, and doesn't look at you."),
)

S["work_boat"] = scene(
    "The ferry", "The river bank",
    say("The boatman has hurt his hand. He needs someone to pole the ferry across with a family and their goat."),
    timing("Push against the current. Keep her straight.", hits=3, speed=1.0, zone=0.2,
           miss="The current swings the bow round.", good=["Steady.", "Steady.", "The far bank."]),
    wage(1, per=1, say="The boatman pays you from the fares."),
    end("The Tiber floods every few years, and every year takes someone."),
)

# ---------- rides: the litter, the cart and the boat, for the long walks ----------

from .common import ride


def _ride(sid, title, where, opening, fare, carried, waits):
    """A ride to one of three far places ({a}, {b}, {c}, filled by the hall from where you stand):
    a fare in each age's coin, an hour of the day, and the walk done in a fade."""
    steps = [say(opening), ask("Where to?", opt("To {a}", then="a"), opt("To {b}", then="b"), opt("To {c}", then="c"),
                                opt("Nowhere. I'll walk.", then="no"))]
    for key in "abc":
        steps += [label(key), pay(fare, els="poor"), ride(key), end(carried)]
    steps += [label("no"), end(waits), label("poor"), end("Not for what's in your purse. " + waits)]
    return scene(title, where, *steps)


S["ride_litter"] = _ride(
    "ride_litter", "The litter", "The street",
    "Four bearers and a covered litter for hire by the hour, the poles on their shoulders, the curtains drawn. The rich are carried everywhere; a man on foot in a litter street is a man without a litter. Where to? {a}, {b} or {c} are a long way on foot.",
    3, "You lie back on the cushions; the street goes by in the gap of the curtain, at the bearers' trot, an hour of it. They set you down and hold out a hand for the tip.",
    "The bearers settle back in the shade of the wall.")
S["ride_cart"] = _ride(
    "ride_cart", "The mule cart", "The street",
    "A muleteer with an empty cart, going back for another load. Carts may not use the streets by day; his may, he says, because it carries for the temples, and he winks. For a coin he will take a passenger. Where to? {a}, {b} or {c}.",
    1, "You sit on the tailboard with your legs hanging over the basalt, the mules' bells going, the wheels finding every rut for an hour. He stops and points with his whip: there.",
    "He shrugs and clicks to the mules.")
S["ride_boat"] = _ride(
    "ride_boat", "The boat", "The river bank",
    "A boatman with a flat skiff, a pole and a sail he never uses. The river is the quickest road in Rome for anywhere on it or across it: the port, the island, the Campus, the far bank. Where to? {a}, {b} or {c}.",
    2, "He poles out into the stream and lets the Tiber do the work, brown and quick and smelling of the drain, under the bridges, an hour of it. He runs her in at the steps and holds her steady with the pole.",
    "He sits down again on his thwart and looks at the water.")

# ---------- the market ----------

BUY = {
    "lanius": ["a cut of pork", 3], "cetarius": ["a fish", 2], "holitor": ["a bunch of leeks", 1], "pomarius": ["a basket of figs", 1],
    "olearius": ["a jar of oil", 4], "vinarius": ["a jug of wine", 3], "popinarius": ["a bowl of stew", 1], "botularius": ["a sausage", 1],
    "crustularius": ["a honey cake", 1], "vestiarius": ["a cloak", 12], "sutor": ["a pair of sandals", 6], "figulus": ["a cooking pot", 2],
    "lucernarius": ["a clay lamp", 1], "unguentarius": ["a flask of perfume", 10], "aurifex": ["a gold ring", 40],
    "purpurarius": ["a length of purple cloth", 60], "textrix": ["a length of wool", 5], "librarius": ["a book", 8],
}
for job, (item, value) in BUY.items():
    S["buy_" + job] = scene(
        "Buying", "At the stall",
        play("haggle", win="bought", lose="none", buying=True, item=item, value=value),
        label("bought"),
        end("Bought."),
        label("none"),
        end("No deal."),
    )

# ---------- dice and boards ----------

S["dice_tali"] = scene(
    "Knucklebones", "The tavern",
    say("A man with a cup of four knucklebones. Dice are illegal except at the Saturnalia. Everyone plays."),
    play("tali", win="won", lose="lost", stake=2),
    label("won"),
    end("He pays you, with a look."),
    label("lost"),
    end("You pay him. He buys a round with it."),
)
S["dice_tali_heroic"] = scene(
    "Knucklebones", "The tavern, 280 BC",
    say("Knucklebones for a cup of wine. No one's ever heard of a law against it; there's hardly anything to bet."),
    play("tali", win="won", lose="lost", stake=1),
    label("won"), end("He pours you the cup. \"The Venus likes you.\""),
    label("lost"), end("You pour him the cup. He drinks to Mars and the legions."),
)
S["dice_tali_republic"] = scene(
    "Knucklebones", "The tavern, about 50 BC",
    say("Dice are against the law. The aedile's men come round sometimes and fine the tavern keeper, who pays them to go away."),
    play("tali", win="won", lose="lost", stake=3),
    label("won"), end("You win. The man says you're lucky. He means something else."),
    label("lost"), end("You lose. Mark Antony, they say, gambled away a fortune and had a friend exiled for it pardoned."),
)
S["dice_tali_empire"] = scene(
    "Knucklebones", "The tavern, about AD 150",
    say("Everyone plays. The Emperor Claudius wrote a book on dice and had a board fixed in his carriage."),
    play("tali", win="won", lose="lost", stake=3),
    label("won"), end("You win."), label("lost"), end("You lose."),
)
S["dice_duodecim"] = scene(
    "Twelve lines", "On the steps",
    say("A board scratched into the stone: three rows of twelve. Five men each, three dice. A lone man hit goes back to the start."),
    play("duodecim", win="won", lose="lost", stake=2),
    label("won"), end("\"Again?\" he says. It's always again."),
    label("lost"), end("He sweeps up your coins and looks for the next man."),
)
S["board_latrunculi"] = scene(
    "The soldiers' game", "With the soldiers",
    say("A board of eight by eight, and glass counters: the soldiers' game. Shut an enemy in between two of yours and he's taken."),
    play("latrunculi", win="won", lose="lost", stake=2),
    label("won"), end("\"You've been a soldier,\" he says. \"Or a lawyer.\""),
    label("lost"), end("\"Too many legions, not enough general,\" he says, sweeping the board."),
)
S["board_terni"] = scene(
    "Three in a row", "In the street",
    say("Children play it on the pavement with pebbles, and so do bored guards: three stones each, three in a row."),
    play("terni", win="won", lose="lost", stake=1),
    label("won"), end("You win. The child demands another game."),
    label("lost"), end("You lose to a child. Everyone watching enjoys it."),
)

# ---------- money ----------

S["changer"] = scene(
    "The money changer's table", "The money changer",
    say("The money changer tests coins for merchants: rings them, weighs them, cuts them. He needs a second pair of eyes today."),
    play("changer", win="good", lose="bad"),
    label("good"),
    end("\"You'll do,\" he says. \"Keep one of the good ones. Know what you're holding.\""),
    label("bad"),
    end("\"Stick to spending it,\" he says."),
)

S["lender"] = scene(
    "The moneylender", "The moneylender's table",
    iff({"has": "a debt"}, "owed"),
    say("He lends at one in a hundred a month, which is the law, and more, which isn't. He knows where everyone lives."),
    ask("\"How much?\"",
        opt("Borrow", coin=10, give="a debt", say="He counts it out, and writes your name and your street.",
            ledger="Borrowed from the moneylender.", ledger_key="debt"),
        opt("Nothing today", say="\"Tomorrow, then. Everybody comes tomorrow.\""),
    ),
    end("His slave walks you to the corner, and remembers your face."),
    label("owed"),
    ask("\"You owe me,\" he says. \"With the interest.\"",
        opt("Repay it", pay=12, take="a debt", fides=1, say="He crosses your name out.", need={"price": 12}),
        opt("Ask for more time", fides=-1, say="\"Time costs,\" he says, and writes a bigger number."),
    ),
    end("Debt is older than Rome. The Twelve Tables let creditors cut a debtor's body in pieces. No one ever did. Probably."),
)

S["alms"] = scene(
    "A beggar", "In the street",
    say("A man on the church steps with a bowl. One of his feet is gone."),
    ask("He says the name of Christ and holds out the bowl.",
        opt("Give a coin", pay=1, fides=1, say="He blesses you and your house.", need={"price": 1}),
        opt("Give bread", take="a loaf", fides=2, need={"has": "a loaf"}, say="He eats it at once."),
        opt("Walk on", say="He says the name of Christ to the next person."),
    ),
    end("Alms are the Church's great teaching: the rich are saved by the poor. The poor stay poor."),
)

S["practice_race"] = scene(
    "A practice run", "The Circus Maximus",
    say("A charioteer of the Greens is short of a driver for a practice run in the morning: four horses, the full course."),
    play("race", win="won", lose="lost", drive=True, laps=3),
    label("won"),
    gain(dignitas=1, say="The Greens' trainer writes your name down."),
    end("Charioteers are slaves and freedmen, and some are richer than senators."),
    label("lost"),
    end("They pick you up out of the sand. \"Everyone goes over once,\" the charioteer says. \"The ones who live learn.\""),
)

# ---------- errands across the city ----------

S["errand_merchant"] = scene(
    "An errand", "In the street",
    say("The merchant has a sealed tablet for a customer and no slave free to take it."),
    errand(2, "the sealed tablet"),
    end("\"Don't read it,\" he says. \"And don't lose it. I know your face now.\""),
)
S["errand_senator"] = scene(
    "A message", "In the street",
    say("The senator looks you over and decides you'll do. \"A message, by word of mouth. You'll remember it? Good.\""),
    errand(2, "the senator's message"),
    end("Men have carried messages for the great all their lives, and been paid in the great men's goodwill."),
)
S["errand_matrona"] = scene(
    "An errand", "In the street",
    say("She has a basket for her sister and her slave is sick. Eggs, and a letter under the eggs."),
    errand(1, "the basket"),
    end("\"Mind the eggs,\" she says, \"and the letter more.\""),
)
S["errand_client"] = scene(
    "An errand", "In the street",
    say("His patron wants a book fetched from a friend's house. He has three other errands already."),
    errand(1, "the patron's note"),
    end("A client runs. A patron waits. That is the whole arrangement."),
)

S["patron_help"] = scene(
    "A word with the senator", "The Forum",
    say("You ask the senator if he needs a man."),
    end("He says: come to my house at dawn, with the others. That is how it's done."),
)

SCENES = S

# What to ask people of each trade, and the scene: [label, scene id, ages it applies to (all if missing)].
JOBS = {
    "pistor": ["Ask for a day's work", "work_baker"],
    "fullo": ["Ask for a day's work", "work_fuller"],
    "baiulus": ["Ask for a load to carry", "work_porter"],
    "saccarius": ["Ask for a load to carry", "work_porter"],
    "aquarius": ["Offer to carry water", "work_water"],
    "scriba": ["Ask for copying work", "work_scribe", ["republic", "empire", "late"]],
    "librarius": ["Buy a book", "buy_librarius"],
    "marmorarius": ["Ask for work in the yard", "work_cutter"],
    "cetarius": ["Offer to sell her fish", "work_fish"],
    "nauta": ["Take the boat somewhere", "ride_boat"],
    "lecticarius": ["Hire the litter", "ride_litter"],
    "mulio": ["Ask for a ride on the cart", "ride_cart"],
    "caupo": ["Play at knucklebones", "dice_tali"],
    "popinarius": ["Buy something", "buy_popinarius"],
    "veteranus": ["Play the soldiers' game", "board_latrunculi"],
    "miles": ["Play the soldiers' game", "board_latrunculi"],
    "proletarius": ["Play three in a row", "board_terni"],
    "nummularius": ["Offer to help test coins", "changer"],
    "faenerator": ["Ask about a loan", "lender"],
    "mendicus": ["Give something", "alms"],
    "haruspex": ["Watch him read a liver", "haruspicy"],
    "victimarius": ["Help with the sacrifice", "sacrifice"],
    "auriga": ["Ask to drive a practice run", "practice_race"],
    "mercator": ["Ask if there's a message to carry", "errand_merchant"],
    "senator": ["Offer to carry a message", "errand_senator"],
    "matrona": ["Offer to run an errand", "errand_matrona"],
    "cliens": ["Ask what his patron needs", "errand_client"],
}
for job in BUY:
    JOBS.setdefault(job, ["Buy something", "buy_" + job])
