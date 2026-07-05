#!/bin/bash
# Скачивает Lottie-анимации с Google Noto в assets/noto/.
# Для каждого эмодзи пробует код как есть И без суффикса _fe0f —
# на Noto часть кодов идёт без вариационного селектора.
# Запуск из корня проекта: bash download_noto.sh

set -u
mkdir -p assets/noto
cd assets/noto || exit 1
BASE="https://fonts.gstatic.com/s/e/notoemoji/latest"
EMOJIS="
smile:1f600
loudlyCrying:1f62d
kissingHeart:1f618
heartFace:1f970
starStruck:1f929
relieved:1f60c
winkyTongue:1f61c
woozy:1f974
pensive:1f614
pleading:1f97a
expressionless:1f611
holdingBackTears:1f979
yawn:1f971
unamused:1f612
rage:1f621
sad:1f61e
anxiousWithSweat:1f630
weary:1f629
coldFace:1f976
hotFace:1f975
sick:1f922
vomit:1f92e
sleep:1f634
sleepy:1f62a
thermometerFace:1f912
halo:1f607
poop:1f4a9
moonFaceLastQuarter:1f31c
sparkles:2728
electricity:26a1
fire:1f525
redHeart:2764_fe0f
beatingHeart:1f493
twoHearts:1f495
greyHeart:1fa76
brokenHeart:1f494
fireHeart:2764_fe0f_200d_1f525
footprints:1f463
anatomicalHeart:1fac0
bitingLip:1fae6
rose:1f339
wiltedFlower:1f940
fallenLeaf:1f342
plant:1f331
leaves:1f343
snowflake:2744_fe0f
bubbles:1fae7
ocean:1f30a
tornado:1f32a_fe0f
spaghetti:1f35d
steamingBowl:1f35c
popcorn:1f37f
hotBeverage:2615
clinkingGlasses:1f942
wineGlass:1f377
tropicalDrink:1f379
flyingSaucer:1f6f8
airplaneDeparture:1f6eb
rollerCoaster:1f3a2
balloon:1f388
birthdayCake:1f382
fireworks:1f386
gemStone:1f48e
balanceScale:2696_fe0f
ring:1f48d
question:2753
crossMark:274c
warning:26a0_fe0f
checkMark:2705
newSymbol:1f195
cool:1f192
yinYang:262f_fe0f
plusSign:2795
muscle:1f4aa
raisedFist:270a
foldedHands:1f64f
pinchedFingers:1f90c
splatter:1fadf
dizzyFace:1f635_200d_1f4ab
dottedLineFace:1fae5
exhale:1f62e_200d_1f4a8
thinkingFace:1f914
sparklingHeart:1f496
grinSweat:1f605
fish:1f41f
nailCare:1f485
pinch:1f90f
sunrise:1f305
volcano:1f30b
debris:1f6d8
iceCream:1f368
softIceCream:1f366
pancakes:1f95e
sunglassesFace:1f60e
hairyCreature:1fac8
bone:1f9b4
cherries:1f352
greenSalad:1f957
bug:1f41b
blush:1f60a
snail:1f40c
cooking:1f373
doughnut:1f369
moai:1f5ff
shakingFace:1fae8
tired:1f62b
"
try_dl() {
  # $1 name, $2 code
  curl -fsSL "$BASE/$2/lottie.json" -o "$1.json" 2>/dev/null
}
ok=0; fail=0; failed=""
for item in $EMOJIS; do
  [ -z "$item" ] && continue
  name="${item%%:*}"
  code="${item##*:}"
  # 1) как есть
  if try_dl "$name" "$code"; then ok=$((ok+1)); continue; fi
  # 2) без _fe0f
  nocode="${code//_fe0f/}"
  if [ "$nocode" != "$code" ] && try_dl "$name" "$nocode"; then ok=$((ok+1)); continue; fi
  # не вышло
  rm -f "$name.json"
  fail=$((fail+1)); failed="$failed $name"
done
echo "Готово: $ok скачано, $fail не найдено → assets/noto/"
[ -n "$failed" ] && echo "НЕ найдены:$failed"