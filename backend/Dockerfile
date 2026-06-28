# Build stage
FROM gradle:8.12-jdk17 AS build
WORKDIR /home/gradle/src
COPY --chown=gradle:gradle . .
RUN gradle installDist --no-daemon

# Run stage
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /home/gradle/src/build/install/paceshift-backend/ /app/
EXPOSE 8080
ENTRYPOINT ["/app/bin/paceshift-backend"]
