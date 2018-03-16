#!/usr/bin/env bash

pyversion=3

while [[ $# -gt 0 ]]
do
key=$1
case $key in
    -py|--python)
        if [ $2 == 2 ]; then
            pyversion=2
        fi
    shift # past argument
    shift # past value
    ;;
    *)
    echo "Command $1 not recognized"
    exit
    shift # past argument
    shift # past value
esac
done


warnings=()


USTExampleURL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.1/example-configurations.tar.gz"
USTPython2URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-ubuntu1604-py2712.tar.gz"
USTPython3URL="https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-ubuntu1604-py352.tar.gz"

function download(){
    url=$1
    output=${url##*/}
    curl -L $url > $output --progress-bar
    echo $output
}

function printColor(){

    case $2 in
        "black") col=0;;
          "red") col=1;;
        "green") col=2;;
       "yellow") col=3;;
         "blue") col=4;;
      "magenta") col=5;;
         "cyan") col=6;;
        "white") col=7;;
              *) col=7;;
    esac

    printf "$(tput setaf $col)$1$(tput sgr 0)\n"
}

function printColorOS(){
    printColor "- $1" $2
}

function printUSTBanner(){
 cat << EOM
$(tput setaf 6)
  _   _                 ___
 | | | |___ ___ _ _    / __|_  _ _ _  __
 | |_| (_-</ -_) '_|   \__ \ || | ' \/ _|
  \___//__/\___|_|     |___/\_, |_||_\__|
                            |__/
$(tput sgr 0)
EOM
}

function banner(){

    type="Info"
    color="green"

    while [[ $# -gt 0 ]]
    do
    key=$1
    case $key in
        -m|--message)
        message=$2
        shift # past argument
        shift # past value
        ;;
        -t|--type)
        type=$2
        shift # past argument
        shift # past value
        ;;
        -c|--color)
        color=$2
        shift # past argument
        shift # past value
        ;;
    esac
    done

    if ! [[ $message = *[!\ ]* ]]; then message=${type}; fi

    sep="$(printf -- '=%.0s' {1..20})"

    if [ $color=="green" ]; then
        case $type in
            "Warning") color="yellow";;
            "Error") color="red";;
        esac
    fi

    printColor "\n$sep $message $sep" $color

}

function installpy(){


    case $pyversion in
        2)

            apt-get -qq update
            apt-get -qq install -y python2.7
            apt-get -qq install -y python-pip

            sudo -H pip -qq install --upgrade pip
            sudo -H pip -qq install virtualenv;;

#
#            apt-get -qq install --force-yes python2.7
#            curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
#            python2.7 get-pip.py
#
#            sudo -H pip -qq install virtualenv;;


        3)

            # Ubuntu 16.04
            add-apt-repository ppa:jonathonf/python-3.6 -y
            apt-get -qq update
            apt-get -qq install -y python3.6
            apt-get -qq install -y python3-pip
            sudo -H pip3 -qq install --upgrade pip
            sudo -H pip3 -qq install virtualenv

#            # Ubuntu 12.04
#            apt-get -qq install -y python-software-properties
#            add-apt-repository ppa:fkrull/deadsnakes -y
#            apt-get -qq update
#            apt-get -qq install --force-yes python3.5
#
#            curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
#            python3.5 get-pip.py
#
#            sudo -H pip -qq install virtualenv;;
    esac



}


function getPackages(){

    apt-get -qq update
    apt-get -qq install -y curl
    apt-get -qq install -y openssl
    apt-get -qq install -y libssl-dev

    installpy
}

function getUSTFiles(){
    USTFolder=$1

    case $pyversion in
        2) USTUrl=$USTPython2URL;;
        3) USTUrl=$USTPython3URL;;
    esac

    USTArch=$(download $USTUrl)
    EXArch=$(download $USTExampleURL)

    mkdir $USTFolder/examples
    tar -zxvf $USTArch -C $USTFolder
    tar -zxvf $EXArch -C $USTFolder
    rm $USTArch $EXArch

    cp "$USTFolder/examples/config files - basic/1 user-sync-config.yml" "$USTFolder/user-sync-config.yml"
    cp "$USTFolder/examples/config files - basic/2 connector-umapi.yml" "$USTFolder/connector-umapi.yml"
    cp "$USTFolder/examples/config files - basic/3 connector-ldap.yml" "$USTFolder/connector-ldap.yml"

    printf "#!/usr/bin/env bash\n./user-sync --users all --process-groups -t" > "$USTFolder/run-user-sync-test.sh"
    printf "#!/usr/bin/env bash\n./user-sync --users all --process-groups" > "$USTFolder/run-user-sync.sh"

    SSLString="openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout private.key -out certificate_pub.crt"
    printf "#!/usr/bin/env bash\n$SSLString" > "$USTFolder/sslCertGen.sh"

}

function configureInstallDirectory(){
    local USTInstallDir="${PWD}/UST_Install"
    if [ -d $USTInstallDir ]; then
        rm -rf $USTInstallDir
    fi
    mkdir $USTInstallDir
    echo $USTInstallDir
}

function testVersion(){
    version=$(lsb_release -r)

    varr=($(lsb_release -r))
    ver=${varr[1]}

    ver="12.04.5"
    ver2=$ver | cut -c1-4

    str=$(echo $ver | cut -c1-5)
    echo $str
   # echo $ver2 + 14.04 | bc
}

function main(){

    printUSTBanner

    testVersion
    getPackages
    getUSTFiles $(configureInstallDirectory)


#    warnings+=(Test)
#    warnings+=(Tes2222)

    if [ ${#warnings[@]} -gt 0 ]; then
        printColor "Install completed with some warnings: " yellow

        for w in ${warnings[@]}; do
            printColorOS $w red
        done

        echo ""
    fi

}

main