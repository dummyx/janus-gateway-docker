FROM debian:bookworm

RUN apt-get -y update && \
	apt-get install -y \
		libavutil-dev \
		libavformat-dev \
		libavcodec-dev \
		libmicrohttpd-dev \
		libjansson-dev \
		libssl-dev \
		libsofia-sip-ua-dev \
		libglib2.0-dev \
		libopus-dev \
		libogg-dev \
		libcurl4-openssl-dev \
		liblua5.3-dev \
		libconfig-dev \
		libusrsctp-dev \
		libwebsockets-dev \
		libnanomsg-dev \
		librabbitmq-dev \
		pkg-config \
		gengetopt \
		libtool \
		automake \
		build-essential \
        meson \
		wget \
		git \
		gtk-doc-tools && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*


RUN cd /tmp && \
	wget https://github.com/cisco/libsrtp/archive/v2.6.0.tar.gz && \
	tar xfv v2.6.0.tar.gz && \
	cd libsrtp-2.6.0 && \
	./configure --prefix=/usr --enable-openssl && \
	make shared_library && \
	make install

RUN cd /tmp && \
	git clone -b 0.1.18 --depth 1 https://gitlab.freedesktop.org/libnice/libnice && \
	cd libnice && \
    meson --prefix=/usr build && \
    ninja -C build && \
    ninja -C build install


RUN git clone -b v1.2.1 https://github.com/meetecho/janus-gateway.git && \
    cd janus-gateway && \
	sh autogen.sh && \
	./configure --enable-post-processing --prefix=/usr/local && \
	make && \
	make install && \
	make configs

FROM debian:bookworm-slim

ARG BUILD_DATE="undefined"
ARG GIT_BRANCH="undefined"
ARG GIT_COMMIT="undefined"
ARG VERSION="undefined"

LABEL build_date=${BUILD_DATE}
LABEL git_branch=${GIT_BRANCH}
LABEL git_commit=${GIT_COMMIT}
LABEL version=${VERSION}

RUN apt-get -y update && \
	apt-get install -y \
		libmicrohttpd12 \
		libavutil-dev \
		libavformat-dev \
		libavcodec-dev \
		libjansson4 \
		libssl3 \
		libsofia-sip-ua0 \
		libglib2.0-0 \
		libopus0 \
		libogg0 \
		libcurl4 \
		liblua5.3-0 \
		libconfig9 \
		libusrsctp2 \
		libwebsockets17 \
		libnanomsg5 \
		librabbitmq4 && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

COPY --from=0 /usr/lib/libsrtp2.so.1 /usr/lib/libsrtp2.so.1
RUN ln -s /usr/lib/libsrtp2.so.1 /usr/lib/libsrtp2.so

COPY --from=0 /usr/lib/x86_64-linux-gnu/libnice.so.10.11.0 /usr/lib/x86_64-linux-gnu/libnice.so.10.11.0
RUN ln -s /usr/lib/libnice.so.10.11.0 /usr/lib/libnice.so.10
RUN ln -s /usr/lib/libnice.so.10.11.0 /usr/lib/libnice.so

COPY --from=0 /usr/local/bin/janus /usr/local/bin/janus
COPY --from=0 /usr/local/bin/janus-pp-rec /usr/local/bin/janus-pp-rec
COPY --from=0 /usr/local/bin/janus-cfgconv /usr/local/bin/janus-cfgconv
COPY --from=0 /usr/local/etc/janus /usr/local/etc/janus
COPY --from=0 /usr/local/lib/janus /usr/local/lib/janus
COPY --from=0 /usr/local/share/janus /usr/local/share/janus

ENV BUILD_DATE=${BUILD_DATE}
ENV GIT_BRANCH=${GIT_BRANCH}
ENV GIT_COMMIT=${GIT_COMMIT}
ENV VERSION=${VERSION}

EXPOSE 10000-10200/udp
EXPOSE 8188
EXPOSE 8088
EXPOSE 8089
EXPOSE 8889
EXPOSE 8000
EXPOSE 7088
EXPOSE 7089

CMD ["/usr/local/bin/janus"]
