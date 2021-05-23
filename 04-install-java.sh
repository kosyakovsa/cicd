cd /work/cicd
echo ">>>>>>>>>>>>>>>> java >>>>>>>>>>>>>>>>"

echo $1

export JAVAVER="$1"

if [ -z "$JAVAVER" ]; then
	echo "java parameter is not defined. will use default 8 version"
	export JAVAVER="8"
fi

sudo apt-get install -y openjdk-$JAVAVER-jdk

export JAVA_HOME=/usr/lib/jvm/java-$JAVAVER-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin

echo "do not forget set JAVA_HOME permanently"

echo "<<<<<<<<<<<<<<<<< java complete <<<<<<<<<<<<<<<<"