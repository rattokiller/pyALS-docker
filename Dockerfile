#FROM ubuntu:focal
FROM debian:11 
LABEL maintainer="Salvatore Barone <salvator.barone@gmail.com>"

# Install prerequisites
RUN apt-get update
RUN apt-get install --fix-missing -y git bison clang cmake curl flex fzf g++ gnat gawk libffi-dev libreadline-dev libsqlite3-dev \
    libssl-dev make p7zip-full pkg-config python3 python3-dev python3-pip tcl-dev vim-nox wget xdot zlib1g-dev zlib1g-dev zsh \
    libboost-dev libboost-filesystem-dev libboost-graph-dev libboost-iostreams-dev libboost-program-options-dev \
    libboost-python-dev libboost-serialization-dev libboost-system-dev libboost-thread-dev sqlite3
RUN wget --quiet https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN git clone https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install
RUN sed -i "s/robbyrussell/af-magic/g" ~/.zshrc
RUN sed -i "s/git/git fzf zsh-autosuggestions zsh-autocomplete/g" ~/.zshrc
RUN ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so /usr/lib/x86_64-linux-gnu/libtinfo.so.5
RUN ln -fs /usr/lib/x86_64-linux-gnu/libboost_python39.a /usr/lib/x86_64-linux-gnu/libboost_python.a
RUN ln -fs /usr/lib/x86_64-linux-gnu/libboost_python39.so /usr/lib/x86_64-linux-gnu/libboost_python.so
RUN echo "/usr/local/lib/" >> /etc/ld.so.conf
RUN ldconfig
WORKDIR /
RUN git clone https://github.com/YosysHQ/yosys
RUN git clone https://github.com/ghdl/ghdl.git
RUN git clone https://github.com/ghdl/ghdl-yosys-plugin.git

RUN wget https://github.com/Kitware/CMake/releases/download/v3.17.0/cmake-3.17.0.tar.gz
RUN apt remove -y cmake
RUN tar -xzf cmake-3.17.0.tar.gz
WORKDIR /cmake-3.17.0
RUN ./bootstrap
RUN make -j `nproc`
RUN make install
RUN ln -s /usr/local/bin/cmake /usr/bin

WORKDIR /ghdl
RUN ./configure --prefix=/usr/local
RUN make
RUN make install

WORKDIR /yosys
ADD resources/Makefile.conf .
ADD resources/yosys.cc.patch .
RUN patch kernel/yosys.cc < yosys.cc.patch
RUN rm yosys.cc.patch
RUN make -j `nproc` 
RUN make install
RUN ln -s /yosys/yosys /usr/bin
RUN ln -s /yosys/yosys-abc /usr/bin

WORKDIR /ghdl-yosys-plugin
RUN make
RUN make install
WORKDIR /root
ADD resources/requirements.txt .
RUN pip3 install -r requirements.txt

WORKDIR /root
RUN git clone https://github.com/SalvatoreBarone/pyALS-lut-catalog.git
RUN git clone https://github.com/SalvatoreBarone/pyALS.git
RUN git clone https://github.com/SalvatoreBarone/pyALS-RF.git
RUN git clone https://github.com/albmoriconi/dtcgen.git

WORKDIR /root/pyALS-lut-catalog
RUN ./import.sh
RUN ln -s /root/pyALS-lut-catalog/lut_catalog.db /root/pyALS/lut_catalog.db
RUN ln -s /root/pyALS-lut-catalog/lut_catalog.db /root/pyALS-RF/lut_catalog.db

WORKDIR /root/pyALS
RUN pip3 install -r requirements.txt 
WORKDIR /root/pyALS-RF
RUN pip3 install -r requirements.txt
WORKDIR /root/dtcgen
RUN pip3 install -r requirements.txt

