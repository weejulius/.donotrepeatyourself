#!/usr/bin/env bash

# Ensure this file is executable via chmod a+x lein, then place it
# somewhere on your $PATH, like ~/bin. The rest of Leiningen will be
# installed upon first run into the ~/.lein/self-installs directory.

export LEIN_VERSION="2.0.0"

case $LEIN_VERSION in
    *SNAPSHOT) SNAPSHOT="YES" ;;
    *) SNAPSHOT="NO" ;;
esac

if [[ "$OSTYPE" == "cygwin" ]]; then
    delimiter=";"
else
    delimiter=":"
fi

function make_native_path {
    # ensure we have native paths
    if [[ "$OSTYPE" == "cygwin" && "$1"  == /* ]]; then
    echo -n "$(cygpath -wp "$1")"
    else
    echo -n "$1"
    fi
}

#  usage : add_path PATH_VAR [PATH]...
function add_path {
    local path_var="$1"
    shift
    while [ -n "$1" ];do
        # http://bashify.com/?Useful_Techniques:Indirect_Variables:Indirect_Assignment
    export ${path_var}="${!path_var}${delimiter}$(make_native_path "$1")"
    shift
    done
}

if [ `id -u` -eq 0 ] && [ "$LEIN_ROOT" = "" ]; then
    echo "WARNING: You're currently running as root; probably by accident."
    echo "Press control-C to abort or Enter to continue as root."
    echo "Set LEIN_ROOT to disable this warning."
    read _
fi

NOT_FOUND=1
ORIGINAL_PWD="$PWD"
while [ ! -r "$PWD/project.clj" ] && [ "$PWD" != "/" ] && [ $NOT_FOUND -ne 0 ]
do
    cd ..
    if [ "$(dirname "$PWD")" = "/" ]; then
        NOT_FOUND=0
        cd "$ORIGINAL_PWD"
    fi
done

export LEIN_HOME="${LEIN_HOME:-"$HOME/.lein"}"

for f in "$LEIN_HOME/leinrc" ".leinrc"; do
  if [ -e "$f" ]; then
    source "$f"
  fi
done

if [ "$OSTYPE" = "cygwin" ]; then
    export LEIN_HOME=`cygpath -w "$LEIN_HOME"`
fi

LEIN_JAR="$LEIN_HOME/self-installs/leiningen-$LEIN_VERSION-standalone.jar"

# normalize $0 on certain BSDs
if [ "$(dirname "$0")" = "." ]; then
    SCRIPT="$(which $(basename "$0"))"
else
    SCRIPT="$0"
fi

# resolve symlinks to the script itself portably
while [ -h "$SCRIPT" ] ; do
    ls=`ls -ld "$SCRIPT"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        SCRIPT="$link"
    else
        SCRIPT="$(dirname "$SCRIPT"$)/$link"
    fi
done

BIN_DIR="$(dirname "$SCRIPT")"

# Try to make the default more sane for :eval-in :classloader.lein
grep -E -q '^\s*:eval-in\s+:classloader\s*$' project.clj 2> /dev/null &&
LEIN_JVM_OPTS="${LEIN_JVM_OPTS:-"-Xms64m -Xmx512m"}"

if [ -r "$BIN_DIR/../src/leiningen/version.clj" ]; then
    # Running from source checkout
    LEIN_DIR="$(dirname "$BIN_DIR")"

    # Need to use lein 1.x to bootstrap the leiningen-core library (for aether)
    if [ "$(ls "$LEIN_DIR"/leiningen-core/lib/*)" = "" ]; then
        echo "Leiningen is missing its dependencies."
        echo "Please see \"Building\" in CONTRIBUTING.md."
        exit 1
    fi

    # If project.clj for lein or leiningen-core changes, we must recalculate
    LAST_PROJECT_CHECKSUM=$(cat "$LEIN_DIR/.lein-project-checksum" 2> /dev/null)
    PROJECT_CHECKSUM=$(sum "$LEIN_DIR/project.clj" "$LEIN_DIR/leiningen-core/project.clj")
    if [ "$PROJECT_CHECKSUM" != "$LAST_PROJECT_CHECKSUM" ]; then
        if [ -r "$LEIN_DIR/.lein-classpath" ]; then
            rm "$LEIN_DIR/.lein-classpath"
        fi
    fi

    # Use bin/lein to calculate its own classpath since src/ and
    # leiningen-core/lib/*jar suffices to run the classpath task.
    if [ ! -r "$LEIN_DIR/.lein-classpath" ] && [ "$1" != "classpath" ]; then
        echo "Recalculating Leiningen's classpath."
        ORIG_PWD="$PWD"
        cd "$LEIN_DIR"

        $0 classpath .lein-classpath
        sum "$LEIN_DIR/project.clj" "$LEIN_DIR/leiningen-core/project.clj" > \
            .lein-project-checksum
        cd "$ORIG_PWD"
    fi

    mkdir -p "$LEIN_DIR/target/classes"
    export LEIN_JVM_OPTS="${LEIN_JVM_OPTS:-"-Xms64m -Xmx256m"} -Dclojure.compile.path=$LEIN_DIR/target/classes"
    add_path CLASSPATH "$LEIN_DIR/leiningen-core/src/" "$LEIN_DIR/leiningen-core/resources/" \
                          "$LEIN_DIR/test:$LEIN_DIR/target/classes" "$LEIN_DIR/src" ":$LEIN_DIR/resources"

    if [ -r "$LEIN_DIR/.lein-classpath" ]; then
        add_path CLASSPATH "$(cat "$LEIN_DIR/.lein-classpath" 2> /dev/null)"
    else
        add_path CLASSPATH "$LEIN_DIR/leiningen-core/lib/*"
    fi
else # Not running from a checkout
    add_path CLASSPATH "$LEIN_JAR"

    BOOTCLASSPATH="-Xbootclasspath/a:$LEIN_JAR"

    if [ ! -r "$LEIN_JAR" -a "$1" != "self-install" ]; then
        "$0" self-install
    fi
fi

if [ "$HTTP_CLIENT" = "" ]; then
    if type -p curl >/dev/null 2>&1; then
        if [ "$https_proxy" != "" ]; then
            CURL_PROXY="-x $https_proxy"
        fi
        HTTP_CLIENT="curl $CURL_PROXY -f -L -o"
    else
        HTTP_CLIENT="wget -O"
    fi
fi

function download_failed_message {
    echo "Failed to download $1"
    echo "It's possible your HTTP client's certificate store does not have the"
    echo "correct certificate authority needed. This is often caused by an"
    echo "out-of-date version of libssl. Either upgrade it or set HTTP_CLIENT"
    echo "to turn off certificate checks:"
    echo "  export HTTP_CLIENT=\"wget --no-check-certificate -O\" # or"
    echo "  export HTTP_CLIENT=\"curl --insecure -f -L -o\""
}

# TODO: explain what to do when Java is missing
export JAVA_CMD="${JAVA_CMD:-"java"}"
export LEIN_JAVA_CMD="${LEIN_JAVA_CMD:-$JAVA_CMD}"

if [[ "$(basename "$LEIN_JAVA_CMD")" == *drip* ]]; then
    export DRIP_INIT="$(printf -- '-e\n(require (quote leiningen.repl))')"
fi

# Support $JAVA_OPTS for backwards-compatibility.
export JVM_OPTS="${JVM_OPTS:-"$JAVA_OPTS"}"

# TODO: investigate http://skife.org/java/unix/2011/06/20/really_executable_jars.html
# If you're packaging this for a package manager (.deb, homebrew, etc)
# you need to remove the self-install and upgrade functionality or see lein-pkg.
if [ "$1" = "self-install" ]; then
    if [ -r "$LEIN_JAR" ]; then
      echo "The self-install jar already exists at $LEIN_JAR."
      echo "If you wish to re-download, delete it and rerun \"$0 self-install\"."
      exit 1
    fi
    echo "Downloading Leiningen to $LEIN_JAR now..."
    mkdir -p "$(dirname "$LEIN_JAR")"
    LEIN_URL="https://leiningen.s3.amazonaws.com/downloads/leiningen-$LEIN_VERSION-standalone.jar"
    $HTTP_CLIENT "$LEIN_JAR.pending" "$LEIN_URL"
    if [ $? == 0 ]; then
        # TODO: checksum
        mv -f "$LEIN_JAR.pending" "$LEIN_JAR"
    else
        rm "$LEIN_JAR.pending" 2> /dev/null
        download_failed_message "$LEIN_URL"
        if [ $SNAPSHOT = "YES" ]; then
            echo "See README.md for SNAPSHOT-specific build instructions."
        fi
        exit 1
    fi
elif [ "$1" = "upgrade" ]; then
    if [ "$LEIN_DIR" != "" ]; then
        echo "The upgrade task is not meant to be run from a checkout."
        exit 1
    fi
    if [ $SNAPSHOT = "YES" ]; then
        echo "The upgrade task is only meant for stable releases."
        echo "See the \"Hacking\" section of the README."
        exit 1
    fi
    if [ ! -w "$SCRIPT" ]; then
        echo "You do not have permission to upgrade the installation in $SCRIPT"
        exit 1
    else
        # TODO: change to stable when 2.0.0 is released
        TARGET_VERSION="${2:-preview}"
        echo "The script at $SCRIPT will be upgraded to the latest $TARGET_VERSION version."
        echo -n "Do you want to continue [Y/n]? "
        read RESP
        case "$RESP" in
            y|Y|"")
                echo
                echo "Upgrading..."
                TARGET="/tmp/lein-$$-upgrade"
                if [ "$OSTYPE" = "cygwin" ]; then
                    TARGET=`cygpath -w $TARGET`
                fi
                LEIN_SCRIPT_URL="https://github.com/technomancy/leiningen/raw/$TARGET_VERSION/bin/lein"
                $HTTP_CLIENT "$TARGET" "$LEIN_SCRIPT_URL"
                if [ $? == 0 ]; then
                    mv "$TARGET" "$SCRIPT" \
                        && chmod +x "$SCRIPT" \
                        && echo && "$SCRIPT" self-install \
                        && echo && echo "Now running" `$SCRIPT version`
                    exit $?
                else
                    download_failed_message "$LEIN_SCRIPT_URL"
                fi;;
            *)
                echo "Aborted."
                exit 1;;
        esac
    fi
else
    if [ "$OSTYPE" = "cygwin" ]; then
        # When running on Cygwin, use Windows-style paths for java
        ORIGINAL_PWD=`cygpath -w "$ORIGINAL_PWD"`
    fi

    # apply context specific CLASSPATH entries
    if [ -f .lein-classpath ]; then
        add_path CLASSPATH "$(cat .lein-classpath)"
    fi

    if [ $DEBUG ]; then
        echo "Leiningen's classpath: $CLASSPATH"
    fi

    if ([ "$LEIN_FAST_TRAMPOLINE" != "" ] || [ -r .lein-fast-trampoline ]) &&
        [ -r project.clj ]; then
        INPUTS="$@ $(cat project.clj) $(cat "$LEIN_HOME/profiles.clj")"
        INPUT_CHECKSUM=$(echo $INPUTS | shasum - | cut -f 1 -d " ")
        # Just don't change :target-path in project.clj, mkay?
        TRAMPOLINE_FILE="target/trampolines/$INPUT_CHECKSUM"
    else
        TRAMPOLINE_FILE="/tmp/lein-trampoline-$$"
        trap "rm -f $TRAMPOLINE_FILE" EXIT
    fi

    if [ "$OSTYPE" = "cygwin" ]; then
        TRAMPOLINE_FILE=`cygpath -w $TRAMPOLINE_FILE`
    fi

    if [ "$INPUT_CHECKSUM" != "" ] && [ -r "$TRAMPOLINE_FILE" ]; then
        if [ $DEBUG ]; then
            echo "Fast trampoline with $TRAMPOLINE_FILE."
        fi
        exec sh -c "exec $(cat $TRAMPOLINE_FILE)"
    else
        export TRAMPOLINE_FILE
        "$LEIN_JAVA_CMD" \
            -client -XX:+TieredCompilation \
            "${BOOTCLASSPATH[@]}" \
            $LEIN_JVM_OPTS \
            -Dfile.encoding=UTF-8 \
            -Dmaven.wagon.http.ssl.easy=false \
            -Dleiningen.original.pwd="$ORIGINAL_PWD" \
            -Dleiningen.script="$SCRIPT" \
            -classpath "$CLASSPATH" \
            clojure.main -m leiningen.core.main "$@"

        EXIT_CODE=$?

        if [ -r "$TRAMPOLINE_FILE" ] && [ "$LEIN_TRAMPOLINE_WARMUP" = "" ]; then
            TRAMPOLINE="$(cat $TRAMPOLINE_FILE)"
            if [ "$INPUT_CHECKSUM" = "" ]; then
                rm $TRAMPOLINE_FILE
            fi
            exec sh -c "exec $TRAMPOLINE"
        else
            exit $EXIT_CODE
        fi
    fi
fi

