FROM ubuntu:20.04

LABEL maintainer = "Santiago Millan Gonzalez <santiago.millang@udc.es>"

#
# Install pre-requistes
#

RUN apt-get update --fix-missing && \
  apt-get install -q -y samtools python && \
  apt-get install -y wget && \
  apt-get install -y unzip && \
  apt-get install -y python3-pip && \
  apt-get install -y openjdk-8-jre && \
  apt-get install -y fastqc 
  
#
# RNA-Seq tools 
# 

RUN wget -q https://github.com/alexdobin/STAR/archive/2.7.9a.tar.gz -O- \
  | tar -xz -C /opt/ && \
  ln -s /opt/STAR-2.7.9a/ /opt/star 
  
RUN wget -q -O gatk.zip https://github.com/broadinstitute/gatk/releases/download/4.2.2.0/gatk-4.2.2.0.zip  && \
  unzip gatk.zip -d /opt/ && \
  rm gatk.zip 

RUN \
  pip3 install multiqc
   
#
# Finalize environment
#

ENV PATH=$PATH:/opt/star/bin/Linux_x86_64:/opt/gatk-4.2.2.0
