"""Your house in the Subura, and your family in it, in each age (home.json and the cena_<age> scenes).

The same house, on the north side of the Argiletum where it climbs toward the Esquiline, from 280 BC
to AD 552: an atrium house with two shops on the street, the atrium and its pool, the household gods,
the dining room, your bedroom, the kitchen and the garden. In every age you have a wife, and every
wife is worse than the one before: Postumia, who spins and keeps the house and is proud of it;
Sulpicia, who mourned her brothers from Cannae for the thirty days the Senate allowed and not an hour
more; Valeria, married without her property passing to you, dining out, threatening divorce; Flavia,
who has her maids flogged for her hair and goes to the games for a gladiator; Rufina, who sells her
daughter to an old man's estates and gives your silver to the bishop; Galla, who lives with a Gothic
guardsman and comes back to sell the household gods. In AD 552 there is no wife and no family, and
the house is broken.

Sources for the manners: Livy 22.56-57 (mourning limited after Cannae; the burials in the cattle
market), 34.1-8 (the Oppian law); Pliny, Natural History 14.89-90 (wine forbidden to women of old);
Sallust, Catiline 25 and Cicero's letters (the women of the late Republic, marriage without manus,
divorce: "tuas res tibi habeto"); Juvenal 6 (the wife of the Empire: the maid Psecas flogged for a
curl, the bread poultice, the gladiator, the astrologers, the drugs against children); Ammianus 28.4
and Jerome's letters (the late Empire's households, legacy hunting, marriages made for estates);
Salvian and Victor of Vita (the Vandal years).
"""

from .common import say, ask, opt, end, label, go, hold, still, timing, pick, gain, iff, scene

AGES = ["heroic", "early", "republic", "empire", "late", "collapse", "fall"]

WIVES = {
    "heroic": {
        "name": "Postumia", "years": 26, "robe": "c8b890", "where": [3.2, 6.2], "yaw": 180,
        "lines": [
            "You're home. Wash your hands, the porridge is on. Marcus has made himself a wooden sword and says he's going to hold the bridge like Horatius.",
            "I finished the cloth for your new tunic. Our own wool, spun and woven here in the atrium, the way my mother did, and hers.",
            "The levy's called. If they take you, go with a clear face. I'll keep the house. That's my part, and I'm proud of it.",
            "I made the offering at the hearth this morning. The Lar looked pleased, I thought. Silly of me. Sit with me a while.",
        ],
        "topics": {
            "who": "Postumia, daughter of Aulus Postumius, your wife these ten years. Are you feeling well?",
            "work": "The house. The wool. The children. The store cupboard and the hearth. Nobody under this roof goes hungry and nobody goes cold.",
            "life": "Good. Hard, and good. Three healthy children and a husband who comes home sober. What more is there?",
            "news": "They say King Pyrrhus has elephants, grey beasts tall as a house. Marcus wants one.",
            "gods": "Vesta keeps the hearth, the Lar keeps the house, Juno keeps women in childbirth. I keep them all fed. I don't touch wine; my grandmother said a wife who drinks has opened the door to worse.",
            "around": "Good people in this street. The widow next door lends me her loom-weights and I lend her salt.",
        },
    },
    "early": {
        "name": "Sulpicia", "years": 38, "robe": "5a4a3e", "where": [-3.5, 1.5], "yaw": 90,
        "lines": [
            "Gaius is home from Africa. Look at him: a man, with a scar he's proud of. I mourned my two brothers after Cannae for thirty days, as the Senate ordered, and not an hour more. Rome needed its rites.",
            "They want to repeal the Oppian law so the women can wear gold and colours again. I'll keep my plain wool. It was good enough while Hannibal was at the gates.",
            "Our girl is betrothed to one of Scipio's veterans. A good man. She'll keep a house like this one.",
            "Don't praise me. Do your duty and I'll do mine. That's a marriage.",
        ],
        "topics": {
            "who": "Sulpicia. Wife of this house, mother of a soldier, sister of two dead ones.",
            "work": "This house runs on my word: the slaves, the stores, the loom, the accounts. You would be lost in a week.",
            "life": "We have lost a great deal and we have won. That is what life is now.",
            "news": "Philip of Macedon. There is always another king.",
            "gods": "After Cannae the priests buried a Gaul and a Greek alive in the cattle market, a man and a woman of each, for the gods. I didn't like it. We won.",
            "around": "Keep Gaius away from the Greek dinners the young men go to. They come home soft.",
        },
    },
    "republic": {
        "name": "Valeria", "years": 34, "robe": "b86a2a", "where": [0.5, 7.0], "yaw": 180,
        "lines": [
            "Oh, you're home. I'm dining out tonight. No, you're not invited. Don't sulk, it's political.",
            "My dowry is mine, my property is mine, and my father can take me home whenever he likes. That's the law, darling, not a threat. Mostly.",
            "The boy? Chrysis has him. She's Greek, he'll learn Greek. I can't be expected to raise a child and keep up with everything.",
            "Everyone divorces now. Pompey's married five times. Cicero's thinking of it. You needn't look like that.",
        ],
        "topics": {
            "who": "Valeria, of the Valerii. Your wife, for the present.",
            "work": "I manage my own estates through my freedman. I read. I dine. I know which senators sleep with which consuls' wives, which is more use than anything you know.",
            "life": "Tedious, when you're home.",
            "news": "Caesar and Pompey, Pompey and Caesar. One of them will win and we'll all have to be charming to him.",
            "gods": "I go to the Good Goddess's rites with the other wives. And an Egyptian reads my stars. He's very good. He says I'll marry again.",
            "around": "The Subura is filthy. We should sell this house and buy on the Palatine. With my money, obviously.",
        },
    },
    "empire": {
        "name": "Flavia", "years": 29, "robe": "5a1e4a", "jewel": True, "where": [-5.0, -3.2], "yaw": 0,
        "lines": [
            "Don't touch me, my face is on: bread and asses' milk, like Poppaea's. It comes off when I go out, for people who matter.",
            "Psecas did my hair badly again. I've had her whipped. What? She's mine.",
            "I'm going to the games. Callistus fights. Don't look like that; every woman in Rome is in love with a net-fighter.",
            "Children? And ruin my figure and split the estate? There are drugs for that. The astrologer says I'll outlive you anyway. I asked him.",
        ],
        "topics": {
            "who": "Flavia. You married my money and I married your name. We are both disappointed.",
            "work": "I spend. Someone has to.",
            "life": "Dull, dull, dull, until the games.",
            "news": "The Emperor is so good he's practically a farmer. Everyone at court is terribly virtuous. Yawn.",
            "gods": "Isis, this month. The priests are charming and the rites are at night.",
            "around": "The Subura. Gods. Get me out of the Subura.",
        },
    },
    "late": {
        "name": "Rufina", "years": 44, "robe": "c8b4d0", "jewel": True, "where": [0.0, -4.0], "yaw": 0,
        "lines": [
            "My lawyer will speak to your lawyer about the farm in Campania. It came to me in my mother's settlement, whatever you think.",
            "Aemilia is betrothed. Anicius Petronius: sixty-one, three estates in Africa, and gout. She'll be a widow in five years and rich. You'll thank me.",
            "The bishop dined with us. I gave the Church the silver you liked. It's for my soul. Your soul is your own business.",
            "Don't come to my rooms. I've had the garden door bricked up.",
        ],
        "topics": {
            "who": "Rufina. Your wife before God, which is the only place it counts now.",
            "work": "I keep what's mine, and some of what's yours, and I give to the poor where the bishop can see me do it.",
            "life": "Life is a vale of tears. Mine is at least well furnished.",
            "news": "The Altar of Victory, the Altar of Victory. Your friends talk of nothing else. The Emperor said no. Let them weep.",
            "gods": "There is one God, and the bishop is his steward, and I pay the steward.",
            "around": "I don't go out on foot. I have a carriage and six eunuchs, and I mean to be seen with them.",
        },
    },
    "collapse": {
        "name": "Galla", "years": 35, "robe": "6a5e5a", "where": [-6.8, 0.5], "yaw": 270,
        "lines": [
            "I've only come for the candlesticks. What's left of them. Don't look at me like that. The Vandals had the rest.",
            "Our boy's in Carthage, if he's alive. I've no money for the bishop's ransom. Have you? No. Then don't talk to me about him.",
            "Wulfila is a Goth, and he's in the palace guard, and he feeds me. You couldn't. That's all there is to say.",
            "I drink. So would you. You do.",
        ],
        "topics": {
            "who": "Galla. I was your wife. The Church says I still am. The Church says a lot of things.",
            "work": "Survive. Sell. Drink. In that order, some days.",
            "life": "What life? The Vandals had it for fourteen days and gave us back the scraps.",
            "news": "There's a new Emperor. There's always a new Emperor. Wulfila says this one won't last a year.",
            "gods": "I pray to Saint Peter and I buy relics. And I still pour a drop for the Lar when no one's looking. Much good any of it did us.",
            "around": "Don't go down by the river at night. Don't go anywhere at night.",
        },
    },
}

# Who else is in the house: [kind, name, note, room x, room z]. kind: child, youth, slave, dog.
HOUSEHOLD = {
    "heroic": [
        ["child", "Marcus", "Marcus, nine, with his wooden sword, holding the bridge of the impluvium against his brother.", 1.6, 3.0],
        ["child", "Lucius", "Lucius, six, the Etruscan army, losing loudly.", -1.4, 4.6],
        ["child", "Tertia", "Tertia, three, asleep on a fleece by the hearth.", -3.0, 5.6],
    ],
    "early": [
        ["youth", "Gaius", "Gaius, nineteen, home from Zama with a scar across his cheek and a mural crown for being first over a wall in Africa.", 2.6, 2.0],
        ["child", "Sulpicia the younger", "Your daughter, twelve, spinning beside her mother, betrothed and proud of it.", -2.8, 3.2],
    ],
    "republic": [
        ["child", "Lucius", "Your son, eight. He answers you in Greek. He calls the nurse mother.", 6.4, 0.5],
        ["slave", "Chrysis", "Chrysis, the Greek nurse. She loves the boy. Someone has to.", 7.0, 1.4],
    ],
    "empire": [
        ["dog", "Myrrhina", "Flavia's lapdog, in a jewelled collar. It is the only child in the house.", -3.6, -3.6],
        ["slave", "Psecas", "Psecas, the hairdresser, with the marks on her back. She does not look at you.", -6.8, -4.6],
        ["slave", "the steward", "The steward, a freedman of Flavia's father. He reports to her, not to you.", 3.0, 6.5],
    ],
    "late": [
        ["child", "Aemilia", "Aemilia, twelve, betrothed to a man of sixty-one. She is embroidering her wedding veil very slowly.", -3.0, -4.2],
        ["slave", "the eunuch", "Rufina's eunuch, in silk. He keeps the keys, and her secrets, and the account of yours.", 1.8, -4.8],
    ],
    "collapse": [],
    "fall": [],
}

# The rooms of the house, as the plan names them, and what each is like in each age.
ROOMS = {
    "atrium": {"name": "The atrium", "notes": {
        "heroic": "The heart of the house: the hearth, the loom, the pool under the opening in the roof where the rain comes in. Everything happens here.",
        "early": "The hearth has moved to the kitchen now. The atrium is for receiving: the loom, the pool, your ancestor's mask in its cupboard.",
        "republic": "Painted walls, a mosaic floor, a strongbox chained to the floor. Valeria had it all redone with her money and reminds you of it.",
        "empire": "Marble, a bronze statue of a satyr by the pool, lamps on silver stands. It is magnificent, and nobody sits in it.",
        "late": "The paintings are faded and a chi-rho has been painted over the satyr's place. The pool is green.",
        "collapse": "Stripped. The Vandals took the bronze fittings and the doors of the strongbox. The pool is dry and full of plaster.",
        "fall": "The roof has fallen into the pool. There are loom-weights in the rubble, from a woman three hundred years dead.",
    }},
    "garden": {"name": "The garden", "notes": {
        "heroic": "Beans, leeks, cabbages, a fig tree. The garden feeds the house.",
        "early": "Vegetables and the fig tree, and a bench your son sits on in the evenings, not saying anything about the war.",
        "republic": "The vegetables are gone; there are clipped box hedges and a Greek statue. Nobody eats from it.",
        "empire": "A fountain, marble, hedges cut into beasts. The gardener is a slave from Syria who has never seen a turnip.",
        "late": "Overgrown. Rufina had the door from the house bricked up. You go round by the kitchen.",
        "collapse": "Nettles, a burnt couch, a Vandal's broken wine jar.",
        "fall": "Brambles over everything. The fig tree has come back, wild. It is the only thing in the house that has.",
    }},
    "triclinium": {"name": "The dining room", "notes": {
        "heroic": "A table and stools. The family eats sitting up, together, like everyone.",
        "early": "Stools still, and a couch for you alone now, the new fashion. Sulpicia sits.",
        "republic": "Three couches round the table, for nine. Valeria reclines with the men when she dines at home, which is seldom.",
        "empire": "Couches of citron wood and ivory, silver on the table, room for nine and a hired flute girl.",
        "late": "Silk on the couches. Dinner in silence, a eunuch pouring.",
        "collapse": "One couch left, broken. You eat bread standing up.",
        "fall": "Half the room is gone. You can see the sky through where the couches were.",
    }},
    "cubiculum": {"name": "Your bedroom", "notes": {
        "heroic": "A bed with a straw mattress, a chest, a lamp. You and Postumia.",
        "early": "The same bed. Sulpicia sleeps on the left, where the lamp is, and reads the accounts before she sleeps.",
        "republic": "Valeria sleeps in the other bedroom now, when she sleeps at home.",
        "empire": "Your bed. Hers is on the far side of the house, with its own door to the street.",
        "late": "Your bed, alone. She had the door between your rooms bricked up.",
        "collapse": "The bed is gone: the Vandals, or Galla, sold it. A mattress on the floor.",
        "fall": "The roof is on the floor. You sleep in the corner of the atrium where it still holds.",
    }},
    "tablinum": {"name": "The master's room", "notes": {
        "heroic": "The family's papers, such as they are: a few tablets, the boundary of the four iugera, the list of the dead.",
        "early": "The strongbox, the records, and the mask of your grandfather who was aedile, in its cupboard in the wing.",
        "republic": "Valeria's freedman does the accounts here. They are her accounts.",
        "empire": "The records of Flavia's estates, in her steward's hand. Your name is on none of them.",
        "late": "Rufina's lawyer uses it. There is a lawsuit about this very room.",
        "collapse": "The strongbox is open and empty. The papers are ash.",
        "fall": "A wall and a doorway, and the sky.",
    }},
    "kitchen": {"name": "The kitchen", "notes": {
        "heroic": "The hearth is in the atrium; this is a store: grain, oil, the salt.",
        "early": "The new kitchen, with its own hearth. Sulpicia's old nurse cooks, and scolds.",
        "republic": "Chrysis feeds the boy here, away from his mother's guests.",
        "empire": "A cook bought for a fortune from a senator, who cooks for guests, never for the house.",
        "late": "Cold, mostly. Rufina eats with the bishop.",
        "collapse": "Nothing in the jars. Mice.",
        "fall": "A heap of broken amphorae, and the hearthstone.",
    }},
    "shops": {"name": "The shops on the street", "notes": {
        "heroic": "No shops yet: a blank wall to the street, like every Roman house.",
        "early": "You rent one shop to a cobbler, one to a woman who sells beans.",
        "republic": "A wine shop and a barber's. The rent pays for the boy's nurse.",
        "empire": "A goldsmith and a perfumer. Flavia's rents.",
        "late": "One shop empty. The other a relic seller.",
        "collapse": "Both shops smashed and empty.",
        "fall": "Two holes in a wall.",
    }},
}

HOUSE_NOTE = {
    "heroic": "Your house, 280 BC: tufa and timber, one hearth, one table, a wife, three children, and the household gods.",
    "early": "Your house, 201 BC: the same house, older and prouder. A son home from the war.",
    "republic": "Your house, about 50 BC: painted and mortgaged. Your wife's money, your wife's rules.",
    "empire": "Your house, about AD 150: marble and slaves and no children, and nobody in it who loves anyone.",
    "late": "Your house, AD 384: half the doors bricked up, a lawsuit about the rest.",
    "collapse": "Your house, AD 455: looted, the door off its hinge, your wife living with a Goth.",
    "fall": "Your house, AD 552: no roof, no wife, no children. The Lar in his niche, if you kept him.",
}

S = {}

S["cena_heroic"] = scene(
    "Supper", "Your house, 280 BC",
    say("Porridge of spelt, beans, a little cheese. The children sit on stools round the hearth; so does Postumia; so do you. Nobody reclines in this house."),
    ask("Marcus wants a story before bed.",
        opt("Horatius at the bridge", say="He holds the bridge against his brother with a spoon until he falls off the stool."),
        opt("Decius Mus", say="He goes quiet at the part where Decius veils his head. So does his mother."),
        opt("The Sabine women", say="Tertia likes the part where the mothers run out between the armies. She makes you tell it twice."),
    ),
    still("Tertia falls asleep on your knee. Don't move.", secs=6, broke="She stirs. You keep still again.",
          done="Postumia lifts her off you and carries her to bed."),
    say("Postumia banks the fire and says the evening words to the Lar. The house is quiet."),
    end("This is what the legions are for."),
)

S["cena_early"] = scene(
    "Supper", "Your house, 201 BC",
    say("Gaius reclines on the new couch, as a soldier home may; Sulpicia and the girl sit. There is meat tonight, for him."),
    say("He tells of Zama: the elephants coming down the lanes Scipio left open for them, the trumpets turning them back on their own men."),
    ask("He is proud. His mother says nothing. He looks at you.",
        opt("Tell him he did his duty", say="He nods. That's the highest thing he could hear, and he knows it."),
        opt("Tell him a soldier doesn't boast at table", say="He goes red. His mother looks at you with approval, for once."),
        opt("Ask him about the men who didn't come back", say="He stops talking. After a while he names them, one by one. Sulpicia pours him water."),
    ),
    say("Sulpicia doesn't drink wine. No woman of this house ever has."),
    end("Duty at table and duty in the field. The house holds."),
)

S["cena_republic"] = scene(
    "Supper", "Your house, about 50 BC",
    say("You dine alone. The boy ate in the kitchen with Chrysis. Valeria is out."),
    say("She comes in at the second hour of the night, laughing, with a young man: a tribune's secretary. \"A friend,\" she says. \"We were talking about the elections.\""),
    ask("The young man looks at his feet.",
        opt("Have it out with her", say="She says, very calmly, that she can divorce you tomorrow and take her dowry, and then where will the house be?",
            ledger="Quarrelled with your wife over her lover.", ledger_key="wife_republic"),
        opt("Say nothing and go to bed", say="You go to bed. You hear them talking in the atrium, and then not talking.",
            ledger="Looked away from your wife's lover.", ledger_key="wife_republic"),
        opt("Divorce her: \"Take your things and go\"", say="The old words. She laughs, because she was going to say them first, and goes to her father's house in the morning with her slaves and her money.",
            ledger="Divorced your wife with the old words: take your things and go.", ledger_key="wife_republic"),
    ),
    end("In the morning the boy asks the nurse, not either of you, what the shouting was."),
)

S["cena_empire"] = scene(
    "A dinner party", "Your house, about AD 150",
    say("Nine on the couches: Flavia's friends, a rich freedman, a poet who is paid to be witty. Dormice in honey, a boar with dates, Falernian wine."),
    say("A slave girl drops a silver dish. The room goes quiet. Flavia doesn't raise her voice: \"The whip. Here.\""),
    ask("The guests watch you, curious. It is your table.",
        opt("Stop it", say="\"How sweet,\" Flavia says to the room. \"My husband is a philosopher.\" They laugh. The girl is whipped in the kitchen instead, later.",
            fides=1, ledger="Tried to stop your wife having a slave whipped at dinner.", ledger_key="wife_empire"),
        opt("Let it happen", say="It happens, there, between the courses. The poet makes a joke about it. Everyone laughs.",
            ledger="Let your wife have a slave whipped at your table.", ledger_key="wife_empire"),
        opt("Leave the table", say="You go out into the garden. You can hear it from the fountain."),
    ),
    end("Afterwards the house is full of slaves clearing up, and there is nobody in it who loves anyone."),
)

S["cena_late"] = scene(
    "Supper", "Your house, AD 384",
    say("Dinner in silence. Rufina eats little and watches the eunuch pour. Aemilia sits with her eyes down."),
    say("When her mother goes to her prayers, Aemilia whispers: \"Father. Must I marry him?\""),
    ask("She is twelve. He is sixty-one.",
        opt("Tell her she must", say="She nods. She had known.", ledger="Told your daughter she must marry an old man for his estates.", ledger_key="aemilia"),
        opt("Tell her you'll stop it", say="Rufina, from the doorway: \"You can't. The dowry is mine, and the contract is signed.\" She is right.",
            fides=1, ledger="Tried to stop your daughter's marriage to an old man, and couldn't.", ledger_key="aemilia"),
        opt("Say nothing", say="You say nothing. She goes back to her veil."),
    ),
    end("Aemilia goes to her room. You hear her door, and then nothing, all night."),
)

S["cena_collapse"] = scene(
    "The last supper in the house", "Your house, AD 455",
    say("Bread, a little oil. Galla has come back for things to sell. She is drunk, and thin, and wearing a Gothic brooch."),
    say("She goes to the niche of the household gods and takes the little bronze Lar in her hand. \"He's worth something. A few coins. More than he ever gave us.\""),
    ask("She looks at you.",
        opt("Let her take him", say="She puts him in her bag with the candlesticks. The niche is empty.", once="lar_sold",
            ledger="Let your wife sell the household gods.", ledger_key="lar_sold"),
        opt("Take him back from her", say="She lets go. \"Keep your little god, then,\" she says. \"He didn't keep us.\" She spits on the floor and goes.",
            ledger="Kept the household gods from your wife.", ledger_key="lar_sold"),
        opt("Give her money instead", pay=3, need={"price": 3}, say="She takes the money, and puts the Lar back, and doesn't look at you again.",
            ledger="Paid your wife not to sell the household gods.", ledger_key="lar_sold"),
    ),
    end("She goes back to the Goth. The door hangs off one hinge. There's nobody to mend it."),
)

S["cena_fall"] = scene(
    "The empty house", "Your house, AD 552",
    say("There is no supper. There is no one to eat it with. The dining room is open to the sky."),
    still("Stand where the table was, and say their names.", secs=8, broke="A stone falls somewhere in the house.",
          done="Postumia. Sulpicia. Valeria. Flavia. Rufina. Galla. Marcus, Tertia, Gaius, Lucius, Aemilia. The echo comes back off the one wall standing."),
    end("No wife. No children. No house. A fig tree in the garden, grown wild."),
)

SCENES = S
