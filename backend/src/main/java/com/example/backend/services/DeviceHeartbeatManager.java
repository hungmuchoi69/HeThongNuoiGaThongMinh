package com.example.backend.services;

import java.time.LocalDateTime;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

public class DeviceHeartbeatManager {
    private static final ConcurrentHashMap<Integer, LocalDateTime> heartbeatMap = new ConcurrentHashMap<>();

    public static void updateHeartbeat(int luaGaId) {
        heartbeatMap.put(luaGaId, LocalDateTime.now());
    }

    public static LocalDateTime getLastActiveTime(int luaGaId) {
        return heartbeatMap.get(luaGaId);
    }

    public static Set<Integer> getAllTrackedDevices() {
        return heartbeatMap.keySet();
    }

    public static void removeDevice(int luaGaId) {
        heartbeatMap.remove(luaGaId);
    }
}