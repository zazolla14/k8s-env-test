# 文件：Dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl unzip tini git zsh fonts-powerline locales ncurses-term bash && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

# 安装 lnav（官方 release 预编译）

ARG LNAV_VER=0.13.1-beta3
RUN set -eux; \
    curl -L -o /tmp/lnav.zip \
      "https://github.com/tstack/lnav/releases/download/v${LNAV_VER}/lnav-${LNAV_VER}-linux-musl-x86_64.zip" && \
    cd /usr/local && unzip /tmp/lnav.zip && \
    mv /usr/local/lnav-${LNAV_VER}/lnav /usr/local/bin/lnav && \
    chmod +x /usr/local/bin/lnav && \
    rm -rf /usr/local/lnav-${LNAV_VER} /tmp/lnav.zip



# 安装 ttyd（官方 release 预编译）
ARG TTYD_VERSION=1.7.7
RUN curl -L -o /usr/local/bin/ttyd \
      "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64" && \
    chmod +x /usr/local/bin/ttyd


RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.oh-my-zsh/custom/themes/powerlevel10k && \
    sed -i 's|ZSH_THEME=".*"|ZSH_THEME="powerlevel10k/powerlevel10k"|' /root/.zshrc && \
    cp /root/.oh-my-zsh/custom/themes/powerlevel10k/config/p10k-lean.zsh /root/.p10k.zsh && \
    grep -q '\.p10k\.zsh' /root/.zshrc || echo '[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh' >> /root/.zshrc && \
    grep -q 'POWERLEVEL10K_DISABLE_CONFIGURATION_WIZARD' /root/.zshrc || echo 'export POWERLEVEL10K_DISABLE_CONFIGURATION_WIZARD=true' >> /root/.zshrc


WORKDIR /root
ENTRYPOINT ["/usr/bin/tini","--"]

CMD ["ttyd", "--writable", "--check-origin=false", "/bin/zsh"]