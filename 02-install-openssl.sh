# Build openssl no ask for version because troubles with compile
export OPENSSL_VERSION=1.1.0g
export OPENSSL_SHA256="de4d501267da39310905cb6dc8c6121f7a2cad45a7707f76df828fe1b85073af"

echo "========================== start openssl ===================================="
#read

# Build openssl no ask for version because troubles with compile
cd /usr/local/src \
  && wget --no-check-certificate "https://www.openssl.org/source/old/1.1.0/openssl-${OPENSSL_VERSION}.tar.gz" -O "openssl-${OPENSSL_VERSION}.tar.gz" \
  && echo "$OPENSSL_SHA256" "openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c - \
  && tar -zxvf "openssl-${OPENSSL_VERSION}.tar.gz" \
  && cd "openssl-${OPENSSL_VERSION}" \
  && ./config shared --prefix=/usr/local/ssl --openssldir=/usr/local/ssl -Wl,-rpath,/usr/local/ssl/lib \
  && make && make install \
  && mv /usr/bin/openssl /root/ \
  && ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl \
  && rm -rf "/usr/local/src/openssl-${OPENSSL_VERSION}.tar.gz" "/usr/local/src/openssl-${OPENSSL_VERSION}" 

echo "============================ update openssl paths ==============================="
#read

# Update path of shared libraries
echo "/usr/local/ssl/lib" >> /etc/ld.so.conf.d/ssl.conf && ldconfig

echo "======================================== GOST ENGINE =================================="
# Build GOST-engine for OpenSSL
export GOST_ENGINE_VERSION=3bd506dcbb835c644bd15a58f0073ae41f76cb06
export GOST_ENGINE_SHA256="4777b1dcb32f8d06abd5e04a9a2b5fe9877c018db0fc02f5f178f8a66b562025"
apt-get update && apt-get install cmake unzip -y \
  && cd /usr/local/src \
  && wget --no-check-certificate "https://github.com/gost-engine/engine/archive/${GOST_ENGINE_VERSION}.zip" -O gost-engine.zip \
  && echo "$GOST_ENGINE_SHA256" gost-engine.zip | sha256sum -c - \
  && unzip gost-engine.zip -d ./ \
  && cd "engine-${GOST_ENGINE_VERSION}" \
  && sed -i 's|printf("GOST engine already loaded\\n");|goto end;|' gost_eng.c \
  && mkdir build \
  && cd build \
  && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS='-I/usr/local/ssl/include -L/usr/local/ssl/lib' \
   -DOPENSSL_ROOT_DIR=/usr/local/ssl  -DOPENSSL_INCLUDE_DIR=/usr/local/ssl/include -DOPENSSL_LIBRARIES=/usr/local/ssl/lib .. \
  && cmake --build . --config Release \
  && cd ../bin \
  && cp gostsum gost12sum /usr/local/bin \
  && cd .. \
  && cp bin/gost.so /usr/local/ssl/lib/engines-1.1 \
  && rm -rf "/usr/local/src/gost-engine.zip" "/usr/local/src/engine-${GOST_ENGINE_VERSION}" 


echo "=================================== enabling GOST ENGINE (ssl conf) ========================"
# Enable engine
sed -i '6i openssl_conf=openssl_def' /usr/local/ssl/openssl.cnf \
  && echo "" >> /usr/local/ssl/openssl.cnf \
  && echo "# OpenSSL default section" >> /usr/local/ssl/openssl.cnf \
  && echo "[openssl_def]" >> /usr/local/ssl/openssl.cnf \
  && echo "engines = engine_section" >> /usr/local/ssl/openssl.cnf \
  && echo "" >> /usr/local/ssl/openssl.cnf \
  && echo "# Engine scetion" >> /usr/local/ssl/openssl.cnf \
  && echo "[engine_section]" >> /usr/local/ssl/openssl.cnf \
  && echo "gost = gost_section" >> /usr/local/ssl/openssl.cnf \
  && echo "" >> /usr/local/ssl/openssl.cnf \
  && echo "# Engine gost section" >> /usr/local/ssl/openssl.cnf \
  && echo "[gost_section]" >> /usr/local/ssl/openssl.cnf \
  && echo "engine_id = gost" >> /usr/local/ssl/openssl.cnf \
  && echo "dynamic_path = /usr/local/ssl/lib/engines-1.1/gost.so" >> /usr/local/ssl/openssl.cnf \
  && echo "default_algorithms = ALL" >> /usr/local/ssl/openssl.cnf \
  && echo "CRYPT_PARAMS = id-Gost28147-89-CryptoPro-A-ParamSet" >> /usr/local/ssl/openssl.cnf
