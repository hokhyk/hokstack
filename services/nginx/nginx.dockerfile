FROM nginx:1.16
ENV TZ=Asia/Beijing
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ> /etc/timezone
