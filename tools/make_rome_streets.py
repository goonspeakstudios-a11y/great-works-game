"""What the streets of Rome say (docs/rome-city-notes.md 2.2 and 3.2), written to
content/rome/streets.json:
  epitaphs   the inscriptions on the tombs along the roads outside the gates, in the Roman formula
             (stranger, stop and read), each with a line on what it says; one is read at each tomb
  signs      what a shop's painted sign shows, by the keeper's trade (people.json job ids)
  compita    what the crossroads shrines are, age by age: the Lares of the crossing, then the
             Christian niche, then broken
  paving     what each named street is paved with (its "kind" of ribbon: basalt, travertine or earth)
  corners    the streets' names on the corner shops at their junctions, and how they are said

    python3 tools/make_rome_streets.py
"""

import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
OUT = os.path.join(ROOT, "content", "rome", "streets.json")

EPITAPHS = [
    {"text": "STRANGER, STOP AND READ. HERE LIES LUCIUS CORNELIUS SCIPIO, AEDILE, CONSUL, CENSOR, WHO TOOK CORSICA AND THE CITY OF ALERIA.",
     "note": "The old formula: the office, the deed, no feeling. The Scipios' tomb by the Capene Gate is the first of the line of tombs down the Appian Way."},
    {"text": "TO THE SPIRITS OF THE DEAD. GAIUS VETTIUS, FREEDMAN OF GAIUS, BAKER, LIVED 61 YEARS. ANTONIA HIS WIFE MADE THIS FOR HIM AND FOR HERSELF WHILE SHE LIVED.",
     "note": "A freedman's tomb: the trade named with pride, the wife's name after. D M at the top, to the spirits of the dead, on nearly every stone from the emperors on."},
    {"text": "STOP, TRAVELLER, AND LOOK TO YOUR LEFT. I WAS A CHILD OF NINE YEARS, THREE MONTHS AND FOUR DAYS. MY FATHER AND MOTHER SET THIS UP AND WEEP.",
     "note": "The Romans counted the days of a child's life on its stone. Half of all children died before ten, and the roads out of every city are lined with them."},
    {"text": "I WAS NOT. I WAS. I AM NOT. I DO NOT CARE.",
     "note": "Non fui, fui, non sum, non curo: the Epicurean's epitaph, cut on hundreds of stones, sometimes shortened to its initials, N F F N S N C."},
    {"text": "HERE LIES TITUS FLAVIUS HERMES, SOLDIER OF THE TENTH URBAN COHORT, SERVED 18 YEARS, LIVED 40. HIS HEIR SET THIS UP AS HE WISHED.",
     "note": "A soldier's stone gives his unit and his years of service before his years of life. His heir, not his family: soldiers could not marry while they served."},
    {"text": "BATHS, WINE AND LOVE RUIN OUR BODIES, BUT BATHS, WINE AND LOVE MAKE LIFE.",
     "note": "Balnea vina Venus corrumpunt corpora nostra, sed vitam faciunt: a joke for the road, on the tomb of a man who evidently had all three."},
    {"text": "TO AULUS GRANIUS, AUCTIONEER, A MAN OF CONSEQUENCE, WORTHY AND TRUSTED. HE WHO WAS SHOUTING FROM THE PLATFORM IS SILENT NOW. FAREWELL.",
     "note": "An auctioneer's, on the road: his trade was to shout, and his stone says so. The dead speak, the passer-by answers: farewell."},
    {"text": "MAY THE EARTH LIE LIGHT ON YOU. HERE RESTS CLAUDIA PRIMA, AGED 27. SHE WORKED THE WOOL, SHE KEPT THE HOUSE, SHE WAS CHASTE, SHE WAS MERRY.",
     "note": "Sit tibi terra levis, S T T L: may the earth lie light. The wife's virtues are the same on every stone for four centuries: wool, the house, chastity, and once in a while, merry."},
    {"text": "THIS TOMB IS NOT TO PASS TO THE HEIR. WHOEVER DEFILES IT SHALL PAY TWENTY THOUSAND SESTERCES TO THE TREASURY OF THE VESTALS.",
     "note": "H M H N S: hoc monumentum heredem non sequitur. A tomb was property, and the dead protected it with a fine, since no one else would."},
    {"text": "GAIUS, FLUTE-PLAYER, PLAYED FOR THE SACRIFICES ON THE CAPITOL. HE LIES HERE. HIS FRIENDS OF THE GUILD OF FLUTE-PLAYERS MADE THIS.",
     "note": "A guild's stone: the poor were buried by their clubs, which met once a month for dinner and once for each funeral. The flute-players' guild was as old as the kings."},
    {"text": "IN PEACE. AURELIA, WHO LIVED 34 YEARS, A CHRISTIAN, SLEEPS HERE. SHE DEPOSITED ON THE THIRD DAY BEFORE THE IDES OF MAY. IN THE LORD.",
     "note": "The Christian stone: no D M, no office, no years counted from birth but the day of burial, the day she was born to the other life, and the dead 'sleeping'."},
    {"text": "I, WHO LIE HERE, WAS ONCE WHAT YOU ARE. YOU WHO READ WILL BE WHAT I AM.",
     "note": "The stone speaks to whoever reads it, and there is no answer. Every road out of Rome says it a hundred times before the second milestone."},
]

SIGNS = {
    "caupo": "jar", "vinarius": "jar", "pistor": "loaf", "lanius": "knife", "faber": "hammer", "sutor": "shoe",
    "fullo": "cloth", "textor": "cloth", "tonsor": "shears", "medicus": "cup", "unguentarius": "jar", "argentarius": "scales",
    "nummularius": "scales", "librarius": "roll", "olearius": "jar", "piscator": "fish", "figulus": "pot", "vestiarius": "cloth",
}

COMPITA = {
    "heroic": {"style": "lares", "note": "A shrine of the Lares of the crossing (the Lares Compitales): two dancing youths painted on the wall of a little aedicula, a snake below them for the spirit of the place, an altar in front, a garland fresh every morning. The Compitalia in January is their festival, and the whole street eats together."},
    "early": {"style": "lares", "note": "The Lares of the crossing in their aedicula, the garland of the day on it, a pinch of meal on the altar. Each crossing has its own, kept by the people of its street, slaves and freedmen among them; the magistrate of the street sees to its games."},
    "republic": {"style": "lares", "note": "The Lares of the crossing. The Senate banned the street clubs that kept them in 64 BC and Clodius brought them back in 58 as his gangs; the shrine is a party headquarters now, its games a riot."},
    "empire": {"style": "lares", "note": "The Lares of the crossing, with the Emperor's Genius between them since Augustus, who divided the city into 265 wards each with its shrine and its four freedmen masters. The masters wear the toga praetexta one day a year and are prouder of it than of anything."},
    "late": {"style": "christian", "note": "A niche where the Lares were: the two youths painted over, a cross scratched in the plaster, and someone's lamp. The street still keeps it; it is not sure of whom."},
    "collapse": {"style": "broken", "note": "The niche is broken and the altar's top knocked off. Someone has put a jar of flowers in the rubble all the same."},
    "fall": {"style": "base", "note": "A block of travertine at a crossing, a hollow in its top worn by four centuries of small offerings. Nobody knows what it was."},
}

PAVING = {
    "the Sacred Way": "travertine",
    "the Vicus Tuscus": "basalt",
    "the Vicus Iugarius": "basalt",
    "the Argiletum and the Clivus Suburanus": "basalt",
    "the Via Lata": "basalt",
    "the Via Appia": "basalt",
    "the Via Labicana": "basalt",
    "the Via Tiburtina": "basalt",
    "the Via Ostiensis": "basalt",
    "the Alta Semita": "basalt",
    "the Via Recta": "basalt",
    "the road to the Janiculum": "basalt",
    "the Vicus Patricius": "earth",
    "the Vicus Longus": "earth",
    "the Clivus Scauri": "earth",
    "the street of the Esquiline": "earth",
}

CORNERS = {
    "note": "The Romans put no names on their streets: you asked. The painted names on the corner shops are for you, in the letters the shops' notices used.",
    "letters": "red",
}


def main() -> int:
    data = {
        "about": "What the streets say: the tombs' epitaphs, the shops' signs, the crossroads shrines age by age, the streets' paving and the corner names (tools/make_rome_streets.py).",
        "epitaphs": EPITAPHS,
        "signs": SIGNS,
        "compita": COMPITA,
        "paving": PAVING,
        "corners": CORNERS,
    }
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("epitaphs: %d, signs: %d, compita: %d, paving: %d" % (len(EPITAPHS), len(SIGNS), len(COMPITA), len(PAVING)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
