FROM gcr.io/kaggle-images/python:v69

ENV NODE_OPTIONS=--max-old-space-size=4096
ENV PROJ_LIB=/opt/conda/share/proj/
ENV APACHE_SPARK_VERSION 2.4.4
ENV HADOOP_VERSION 2.7
ENV Z_VERSION 0.8.2
ENV Z_HOME /zeppelin
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV SPARK_HOME /spark
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip
ENV PYSPARK_PYTHON /opt/conda/bin/python
ENV MESOS_NATIVE_LIBRARY /usr/local/lib/libmesos.so
ENV SPARK_OPTS --driver-java-options=-Xms4096M --driver-java-options=-Xmx32768M --driver-java-options=-Dlog4j.logLevel=info
ENV SCALA_VERSION 2.12.8
ENV ALMOND_VERSION 0.9.0

RUN useradd -m strops && useradd -m hksitorus && useradd -m arifsolomon && useradd -m fchrulk


COPY mesos.key /tmp/
RUN mkdir -p /var/log/supervisor
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-key add /tmp/mesos.key && \
    echo "deb http://repos.mesosphere.io/debian stretch main" > /etc/apt/sources.list.d/mesosphere.list
RUN echo exit 0 > /usr/bin/systemctl && chmod +x /usr/bin/systemctl
RUN apt-get -y update && \
    apt-get install -y --no-install-recommends \
    nodejs gnupg mesos \
    openjdk-8-jdk  ca-certificates-java \
    supervisor \
    build-essential \
    gfortran \
    libblas-dev libatlas-dev liblapack-dev \
    libpng-dev libfreetype6-dev libxft-dev \
    libxml2-dev libxslt-dev zlib1g-dev \
    fonts-dejavu \
    unixodbc unixodbc-dev \
    r-base r-base-dev \
    r-cran-rodbc \
    gcc \
    locales \
    software-properties-common \
    wget curl grep sed dpkg \
    bzip2 ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN ln -s /bin/tar /bin/gtar

RUN pip install \
    jupyterhub==1.0.0 \
    notebook==6.0.2 \
    jupyterlab==1.2.4 \
    jupyterlab_sql==0.3.1 \
    oauthenticator==0.10.0 \
    psycopg2==2.8.4 \
    cx_Oracle==7.3.0 \
    PyMySQL==0.9.3 \
    intel-tensorflow==2.0.0 \
    pyspark==${APACHE_SPARK_VERSION} \
    fastparquet==0.3.2 \
    jupyterlab_latex==1.0.0 \
    bkzep==0.6.1

RUN npm install -g --unsafe-perm configurable-http-proxy

RUN conda install --quiet --yes -c conda-forge basemap pyproj proj4 ipyleaflet ipysheet
RUN conda install --quiet --yes -c bokeh jupyter_bokeh
RUN conda install --quiet --yes -c pyviz holoviews bokeh
RUN wget https://raw.githubusercontent.com/matplotlib/basemap/master/lib/mpl_toolkits/basemap/data/epsg -O /opt/conda/share/proj/epsg

RUN jupyter serverextension enable jupyterlab_sql --py --sys-prefix
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager@1.1 --no-build
RUN jupyter labextension install plotlywidget@1.3.0 --no-build
RUN jupyter labextension install jupyterlab-plotly@1.3.0 --no-build
RUN jupyter labextension install jupyterlab-drawio --no-build
RUN jupyter labextension install @bokeh/jupyter_bokeh --no-build
RUN jupyter labextension install @mflevine/jupyterlab_html --no-build
RUN jupyter labextension install @jupyterlab/latex --no-build
RUN jupyter labextension install @pyviz/jupyterlab_pyviz --no-build
RUN jupyter labextension install jupyter-leaflet --no-build
RUN jupyter labextension install ipysheet --no-build
RUN jupyter labextension install @aquirdturtle/collapsible_headings --no-build
RUN jupyter lab build


RUN npm install -g --unsafe-perm ijavascript && ijsinstall --install=global


RUN conda install --quiet --yes -c conda-forge \
    'r-caret' \
    'r-crayon' \
    'r-devtools' \
    'r-forecast' \
    'r-hexbin' \
    'r-htmltools' \
    'r-htmlwidgets' \
    'r-irkernel' \
    'r-nycflights13' \
    'r-plyr' \
    'r-randomforest' \
    'r-rcurl' \
    'r-reshape2' \
    'r-rmarkdown' \
    'r-rodbc' \
    'r-rsqlite' \
    'r-shiny' \
    'r-sparklyr' \
    'r-tidyverse' \
    'unixodbc' \
    'r-knitr' \
    'r-ggplot2' \
    'r-googlevis' \
    'r-rcpp' \
    'r-e1071'
RUN Rscript -e "library('devtools'); library('Rcpp'); install_github('ramnathv/rCharts')"


RUN cd /tmp && \
    wget -q http://mirrors.ukfast.co.uk/sites/ftp.apache.org/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    echo "2E3A5C853B9F28C7D4525C0ADCB0D971B73AD47D5CCE138C85335B9F53A6519540D3923CB0B5CEE41E386E49AE8A409A51AB7194BA11A254E037A848D0C4A9E5 *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | sha512sum -c - && \
    tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C / --owner root --group root --no-same-owner && \
    rm spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN cd / && mv spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark


RUN wget -O /tmp/zeppelin-${Z_VERSION}-bin-all.tgz http://archive.apache.org/dist/zeppelin/zeppelin-${Z_VERSION}/zeppelin-${Z_VERSION}-bin-all.tgz && \
    tar -zxvf /tmp/zeppelin-${Z_VERSION}-bin-all.tgz && \
    rm -rf /tmp/zeppelin-${Z_VERSION}-bin-all.tgz && \
    mv /zeppelin-${Z_VERSION}-bin-all ${Z_HOME}


RUN cd /tmp && curl -Lo coursier https://git.io/coursier-cli && chmod +x coursier && \
    ./coursier bootstrap \
    -r jitpack \
    -i user -I user:sh.almond:scala-kernel-api_$SCALA_VERSION:$ALMOND_VERSION \
    sh.almond:scala-kernel_$SCALA_VERSION:$ALMOND_VERSION \
    -o almond && \
    ./almond --install --global --jupyter-path /opt/conda/share/jupyter/kernels && \
    rm -rf coursier almond

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN rm -rf /var/lib/apt/lists/*

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
