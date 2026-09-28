"""The city's other scenes (docs/rome-activities-plan.md, 3.6-3.9, 3.14): the census, the baths,
the fire, a night in the Subura, a day at the races. SPOTS says where and when they are found.
"""

from .common import (say, ask, opt, end, label, go, rite, hold, still, timing, typing, pick, gain, pay, wage, iff, play,
                     scene, hour)

S = {}

# ---------- the census ----------

S["census_early"] = scene(
    "The census", "The Villa Publica, 199 BC",
    say("The censors sit on their curule chairs in the Villa Publica with their clerks. Every citizen must come and declare, under oath, his name, his father, his age, his wife, his children, his property."),
    say("Your property decides your class; your class decides where you stand in the battle line and when your century votes. The rich vote first, and fight in front."),
    ask("The censor asks your property. The clerk waits with his stylus.",
        opt("Declare it honestly", census=0, say="The clerk writes it down. The censor nods and calls the next man."),
        opt("Declare a little more than you have", census=1, fides=-2, say="A higher class: a better century, and a heavier war tax. The censor looks at your cloak.",
            ledger="Declared more property to the censors than you had.", ledger_key="census_lie"),
        opt("Declare less than you have", census=-1, fides=-2, say="A lower class: less tax, and your vote counts for less. The censor writes it.",
            ledger="Hid property from the censors.", ledger_key="census_lie"),
    ),
    iff({"random": 0.25}, "checked"),
    end("At the end of the census the censors will purify the whole people on the Campus: a pig, a sheep and a bull led round the army, and killed. The lustrum."),
    label("checked"),
    say("The censor's clerks check some declarations. A neighbour is asked about you."),
    end("The censors keep the roll of morals too. Cato, when he is censor, will strike a senator off for kissing his wife in daylight in front of their daughter."),
)

S["census_republic"] = scene(
    "The census", "The Villa Publica, about 50 BC",
    say("No census has been completed for twenty years. Every pair of censors since has quarrelled and resigned, or been stopped by tribunes. The rolls are a mess."),
    say("A clerk from the censors' office sits at a table anyway, selling his services."),
    ask("\"I can put you down in any class you like,\" he says. \"The first class is dearer.\"",
        opt("Pay to be written in the first class", pay=10, **{"class": 5}, dignitas=1, fides=-1, need={"price": 10},
            say="He writes you in. No one will ever check.", ledger="Paid a clerk to enrol you in a class you didn't belong to.", ledger_key="census_bribe"),
        opt("Declare honestly, for nothing", census=0, say="He writes it down, bored. \"Honest men,\" he says. \"We get one a month.\""),
        opt("Walk away", say="Nobody knows who is a citizen any more. Everyone is a citizen if he says so loudly enough."),
    ),
    end("The last census counted nine hundred thousand citizens. Nobody knows how many there are now. Nobody counts."),
)

S["census_late"] = scene(
    "The tax assessor", "The Prefect's office, AD 384",
    say("The census is the tax roll now: land, and heads. Every head of household must declare his property and his people, and pays by it, in gold, in kind, in labour."),
    ask("The assessor looks at your papers.",
        opt("Declare everything", pay=6, fides=1, need={"price": 6}, say="You pay. It leaves you almost nothing. Honesty is taxed at the full rate."),
        opt("Slip him something to look away", pay=3, fides=-1, need={"price": 3}, say="He looks away. He's paid more by the rich, to look further.",
            ledger="Bribed the tax assessor.", ledger_key="tax_bribe"),
        opt("Say you have nothing", fides=-2, say="He writes it. If they find out, it's the lead whips.",
            ledger="Lied to the tax assessor.", ledger_key="tax_lie"),
    ),
    end("The great landowners' estates are assessed by their own agents. The small men sell their land to them, and become their tenants, to be protected from the tax."),
)

# ---------- the baths ----------

_CHANGE = ask("In the changing room the attendant, the capsarius, offers to watch your clothes.",
              opt("Pay him to watch them", pay=1, need={"price": 1}, say="He puts your things on a shelf and sits by them.", then="safe"),
              opt("Leave them on the shelf", say="You leave them. Others do.", then="risky"))


def _bathe():
    return [
        timing("First the exercise yard: a ball game with some men from the Subura.", hits=2, speed=1.1, zone=0.22,
               miss="You drop it. They jeer.", good=["Caught.", "Caught."]),
        hold("The hot room. Sit in the steam as long as you can bear it.", secs=4.0, done="You are red as a cooked crab."),
        hold("The cold plunge.", secs=2.0, done="You come up gasping."),
        say("An attendant scrapes the oil and sweat off you with a bronze strigil. Around you people talk: prices, the races, who's sleeping with whom."),
    ]


def _baths(title, where, opening, thief_odds, safe_end, lucky_end, chase_where):
    return scene(
        title, where, say(opening), _CHANGE,
        label("safe"), *_bathe(), end(safe_end),
        label("risky"), *_bathe(), iff({"random": thief_odds}, "stolen"), end(lucky_end),
        label("stolen"),
        ask("Your tunic is gone from the shelf. A boy is slipping out with it.",
            opt("Chase him", then="chase"),
            opt("Let it go", coin=-1, say="You buy a cheap one outside. People write curses on lead against bath thieves.", then="gone")),
        label("chase"),
        hold("Run him down in the %s." % chase_where, secs=2.5, done="You catch him by the hair. He's about ten."),
        ask("He's crying. He has your tunic and nothing else.",
            opt("Take your tunic and let him go", fides=1, say="He's back in the bathhouse tomorrow."),
            opt("Hand him to the bath keeper", say="The keeper takes him away. You never learn what happens to him.",
                ledger="Handed a child thief to the bath keeper.", ledger_key="bath_thief")),
        end("Clean, at least."),
        label("gone"),
        end("Clean, at least, and poorer."),
    )


S["baths_republic"] = _baths(
    "The baths", "A bathhouse in the Subura, about 50 BC",
    "A small bathhouse, a private business: a copper coin to go in. Old men complain that Scipio washed once a week in a dark little room, and was the better for it.",
    0.5, "Clean, and your clothes where you left them.", "Your clothes are where you left them. Lucky.", "alley")

S["baths"] = _baths(
    "The baths", "The great baths",
    "The Emperors' baths: a quarter of an as to go in. Marble from every province, a library, gardens, hot and cold pools, and the whole city at once.",
    0.4, "You come out into the evening clean, oiled and cheerful. The baths are the best thing in Rome, and they are for everyone.",
    "Seneca lived over a bathhouse and complained of the noise: the grunting of the weightlifters, the slap of the masseur, the hair-plucker's shriek, the sausage seller's cry.",
    "colonnade")

S["baths_late"] = scene(
    "The baths", "The Baths of Diocletian, AD 384",
    say("The biggest baths ever built: three thousand bathers at once. The nobles come with fifty servants each and complain that the water is too hot or not hot enough."),
    *_bathe(),
    say("A noble comes in shouting \"Where are my people?\" for his towel-bearers. Ammianus says they march into the baths like generals, with fifty servants behind them."),
    end("The baths still run. The aqueducts still run. For now."),
)

S["baths_collapse"] = scene(
    "The baths", "The Baths of Diocletian, AD 455",
    say("The baths are still open, half of them. The furnaces are cold in the east wing: no one to pay for the wood. The Vandals stripped the bronze fittings."),
    hold("The warm room is barely warm. Sit anyway.", secs=3.0, done="It's better than home."),
    end("A priest outside is preaching that the baths are a sin. The crowd listens, and goes in anyway."),
)

S["baths_fall"] = scene(
    "The baths", "The Baths of Diocletian, AD 552",
    say("The aqueducts were cut in 537. The pools are dry and full of rubbish. Men are burning the marble into lime."),
    still("Stand in the great hall, where three thousand people once bathed.", secs=6, broke="A lime burner shouts at you to move.",
          done="Your footsteps echo under the vault."),
    end("A thousand years later it will be a church, and the pools will be a garden."),
)

# ---------- the fire ----------

_FIRE_CHOICE = ask("It's spreading to the next block. You have to pull a building down to stop it: the empty warehouse, or the house with an old man who won't leave.",
                   opt("Pull down the warehouse", say="The hooks bite; it comes down in a cloud. The fire stops at the gap.", fides=1),
                   opt("Pull down the old man's house", say="They carry him out cursing you. His house stops the fire. He has nowhere to live.",
                       ledger="Pulled down an old man's house to stop a fire.", ledger_key="fire_choice"),
                   opt("Save the old man's house and let the fire decide", say="The fire takes the warehouse, and then the next block. By dawn thirty families are in the street.",
                       ledger="Let a fire spread rather than pull down a house.", ledger_key="fire_choice"))

_FIRE_RESCUE = [
    say("A woman screams from a window on the fourth floor. The stairs are burning."),
    hold("Hold the blanket with the others while she jumps.", secs=3.0, done="She lands. Her ankle is broken. She is alive."),
]

S["fire_early"] = scene(
    "Fire!", "The Subura, 201 BC",
    say("A house is burning in the Subura. There is no fire brigade: the neighbours form a line from the fountain with buckets."),
    timing("Pass the buckets up the line, on the beat.", hits=4, speed=1.0, zone=0.2, miss="You slop it.",
           good=["Up.", "Up.", "Up.", "Up."], done="The flames drop."),
    end("The house is lost. The ones either side are saved. Everyone goes home black with smoke, and the magistrates do nothing, because nobody expects them to."),
)
S["fire_heroic"] = dict(S["fire_early"], where="The Subura, 280 BC")

S["fire_republic"] = scene(
    "Fire!", "The Subura, about 50 BC",
    say("A block of flats is burning. Five storeys of timber and rubble, built cheap and high. There is no public fire brigade."),
    say("A rich man's slave gang arrives with buckets and hooks, and stands watching. Their overseer is buying the burning building from its owner, cheap, and the ones next to it. Then they'll put it out."),
    ask("The owner is weeping and haggling.",
        opt("Tell him to hold out", fides=1, say="He holds out. The gang watches it burn."),
        opt("Join the bucket line instead", then="line"),
    ),
    label("line"),
    timing("Pass the buckets.", hits=3, speed=1.1, zone=0.2, miss="Slopped.", good=["Up.", "Up.", "Up."]),
    *_FIRE_RESCUE,
    end("By morning the rich man owns the street. Crassus made his first fortune this way, and he's dead now, and others do it."),
)

S["fire"] = scene(
    "Fire!", "The Subura",
    say("An insula is burning. The Watch, the vigiles, come at a run: seven thousand freedmen in cohorts, with buckets, pumps, hooks, and blankets soaked in vinegar."),
    timing("Work the pump with the vigiles.", hits=4, speed=1.2, zone=0.2, miss="The pump coughs.", good=["Water.", "Water.", "Water.", "Water."]),
    *_FIRE_RESCUE,
    _FIRE_CHOICE,
    wage(1, say="The vigiles' officer gives you a coin for your trouble."),
    end("Fires start every day in Rome: lamps, braziers, cooking on upper floors. The Great Fire under Nero burned for six days."),
)

S["fire_collapse"] = scene(
    "Fire!", "The Subura, AD 455",
    say("A block is burning. The Watch hasn't been paid in months; a few of them come. Mostly it is neighbours with pots."),
    timing("Pass the pots.", hits=3, speed=1.2, zone=0.2, miss="Slopped.", good=["Up.", "Up.", "Up."]),
    _FIRE_CHOICE,
    end("Half the street is gone by morning. No one will rebuild it. There are empty houses everywhere to move into."),
)

S["fire_fall"] = scene(
    "Smoke", "The Subura, AD 552",
    say("Smoke over the empty quarter. Nobody lives there. Someone set a fire to clear the brambles, or to keep warm, and it took the old roofs."),
    still("Watch it burn. There is nothing to save.", secs=5, done="It burns itself out."),
    end("In the emptied city a fire is just weather."),
)

# ---------- a night in the Subura ----------

S["night"] = scene(
    "Home through the Subura at night", "The Subura, after dark",
    say("Juvenal says you are a fool to go out to dinner without making your will. The streets are black. You walk home."),
    timing("Something comes down from a window above: a broken pot, a chamber pot. Step aside!", hits=1, speed=1.4, zone=0.25, spare=1,
           miss="It catches your shoulder. Wet. Stinking.", good=["It smashes behind you."]),
    say("A drunk blocks the alley: a big man spoiling for a fight. \"Where are you from? Whose beans have you been stuffing yourself with? Answer me!\""),
    ask("He means to hit you whatever you say.",
        opt("Answer him meekly", say="He hits you anyway. You beg to be allowed to go home with a few teeth. That, says Juvenal, is the poor man's liberty.",
            fides=0),
        opt("Hit him first", say="He goes down. His friends come out of the tavern. You run.", then="run"),
        opt("Run", then="run"),
    ),
    label("run"),
    timing("Run for it down the alley.", hits=2, speed=1.3, zone=0.22, miss="You stumble on the cobbles.", good=["Round the corner.", "Clear."]),
    say("A rich man's litter comes past with a long line of slaves and bronze lamps. They shove you into the gutter without looking."),
    iff({"random": 0.4}, "thief"),
    end("Your door. Bolt it. Behind the shutters, all night, the carts and the shouting."),
    label("thief"),
    gain(say="In the dark someone cuts your purse strings.", coin=-2),
    end("Your door. Bolt it. There is no watch in these alleys that you'd want to call."),
)

S["night_republic"] = S["night"]
S["night_fall"] = scene(
    "The city at night", "The Subura, AD 552",
    say("There are no lamps in the windows, because there is no one in the houses."),
    still("Stand in the street and listen.", secs=7, broke="Your own step, loud.", done="An owl. The river. Nothing else in the whole quarter."),
    end("Juvenal's Rome was too full to sleep in. This one is too empty."),
)

# ---------- the races ----------

S["races_bet"] = scene(
    "The races", "The Circus Maximus",
    say("A hundred and fifty thousand people. The four colours: Greens, Blues, Reds, Whites. The whole city is for one or another; men have been killed over it."),
    say("The bookmakers work the crowd under the arches. Under the starting gates, people bury curse tablets against the other colours' horses."),
    play("race", win="won", lose="lost", bet=True, stake=2, laps=7),
    label("won"),
    end("Your colour won! You buy wine for strangers who are suddenly your brothers."),
    label("lost"),
    end("Your colour lost. You can bet again next time. Everybody does."),
)

SCENES = S

# Where and when (hours may wrap past midnight).
SPOTS = [
    {"scene": "baths", "text": "Go into the baths", "monument": "titus_baths", "at": [700, -20],
     "ages": ["empire"], "from": 12.0, "to": 20.0},
    {"scene": "baths", "text": "Go into the baths", "monument": "diocletian_baths", "at": [1000, 1150],
     "ages": ["late", "collapse", "fall"], "from": 12.0, "to": 20.0},
    {"scene": "baths", "text": "Go into the bathhouse", "at": [560, 330], "ages": ["republic"], "from": 12.0, "to": 20.0},
    {"scene": "fire", "text": "Help with the fire", "at": [520, 420], "ages": ["heroic", "early", "republic", "empire", "late", "collapse", "fall"],
     "every": 3, "offset": 2, "from": 14.0, "to": 18.0},
    {"scene": "night", "text": "Walk home through the Subura", "at": [150, 170], "ages": ["republic", "empire", "late", "collapse", "fall"],
     "from": 20.5, "to": 4.5},
    {"scene": "races_bet", "text": "Bet on the races", "monument": "circus", "at": [41, -560], "ages": ["empire", "late"],
     "every": 2, "offset": 1, "from": 12.0, "to": 18.0},
]
