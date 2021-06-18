function getCategories() {
    curl --compressed 'https://www.androidrank.org/js/all-libs.min.js?time=8' | grep -iE 'categories_[a-z]+_names\s*=\s*' | sed 's/.*\[//g' | sed 's/\].*//g' | tr '\n' ',' | sed 's/.$//g' | tr ',' ' '
}
function openGooglePlay(){ 
    adb shell am start "https://play.google.com/store/apps/details?id=$1"  
} 
function uninstallApp(){ 
    adb shell pm uninstall $1
}  
function installApp(){ 
    # TODO: fix failure in some installations
    adb shell 'input keyevent 61  && input keyevent 61 && input keyevent 61 && input keyevent 61 && input keyevent 61 && input keyevent 61 && input keyevent 61 && input keyevent 66'  
}
function stopWaitingInstallation() {
    echo -e '\nstopping wait'; 
    break 2>/dev/null
}
function openApp() {
    trap stopWaitingInstallation 2 
    while ! adb shell pm -lf | grep -qi "$1";do 
        sleep 1
    done
    adb shell monkey -p $app -c android.intent.category.LAUNCHER 1
}
function skippingInstallation() { 
    echo -e '\ngoing to next'; 
    continue 
}

function downloadApps() {
    categories=( $(getCategories) )
    mkdir -p "$1"; cd "$1"
    for category in "${categories[@]}"; do
        category=$(echo $category | tr -d "'")
        echo 'Downloading top 20 from ' $category
        curl -s 'https://www.androidrank.org/android-most-popular-google-play-apps?category='$category'&sort=4' | grep -Eo '<td style="text-align:left;"><a href="[^"]+'  | grep -Eo '/[^/]*$' | sed 's/^.//' > "$category".txt
    done
}


function processCategory() {
    apps=( $(cat "$1" | cut -d',' -f1 ) )
    for app in "${apps[@]}"; do
        if [ ${#app} -le 5 ]; then 
            # checking if length of package name is valid
            continue
        fi; 
        trap skippingInstallation 2
        openGooglePlay $app && sleep 1.5
        echo "Installing" $app
        installApp && openApp $app 
        echo "can uninstall $app ?" && read a && uninstallApp $app
    done 
    echo 'finished category' $category
}


# function processAllCategories() {
#     cd "$1" 2>/dev/null
#     categories=( $(ls -1) )
#     for category in "${categories[@]}"; do
#         echo "processing" $category
#         processCategory $category
#     done
# }
# processAllCategories $appsDirectory

# downloadApps $appsDirectory

appsDirectory="apps"
cd $appsDirectory
processCategory "FINANCE.txt"