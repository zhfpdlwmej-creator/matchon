# ── build ─────────────────────────────────────────────
FROM gradle:8.8-jdk21 AS build
WORKDIR /app
COPY build.gradle settings.gradle gradle.properties ./
# 로컬 전용 JDK 경로(org.gradle.java.home=C:/java/...)는 컨테이너에 없으므로 제거
RUN sed -i '/org.gradle.java.home/d' gradle.properties
COPY src ./src
RUN gradle bootWar --no-daemon -x test

# ── runtime ───────────────────────────────────────────
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/build/libs/*.war app.war
ENV TZ=Asia/Seoul
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0"
# Spring Boot 가 server.port 를 ${PORT} 로 읽으므로 Railway 가 동적 할당
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar app.war"]
