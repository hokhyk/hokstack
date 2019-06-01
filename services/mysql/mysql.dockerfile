FROM mysql:8.0
ENV TZ=Asia/Beijing
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ> /etc/timezone
