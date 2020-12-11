FROM mcr.microsoft.com/azure-cli:2.5.1

RUN az extension add --name connectedk8s --yes --debug

RUN /usr/bin/curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl  \
    &&  mv ./kubectl /usr/local/bin/kubectl

RUN /usr/bin/curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

RUN /usr/bin/wget -O guard https://github.com/appscode/guard/releases/download/v0.6.1/guard-linux-amd64 \
  && chmod +x guard \
  && mv guard /usr/local/bin/

COPY job.sh /

COPY daemonset.sh /

ENTRYPOINT ["/bin/bash", "/job.sh"]