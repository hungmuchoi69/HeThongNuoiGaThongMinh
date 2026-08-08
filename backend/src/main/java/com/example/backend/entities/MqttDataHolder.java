package com.example.backend.entities;

import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;

import lombok.Data;

@Component
public class MqttDataHolder {
    private final ConcurrentHashMap<UUID, SensorData> userStotage = new ConcurrentHashMap<>();
    @Data
    public static class SensorData {
        private volatile float nhiet_do;
        private volatile float do_am;
        private volatile int tds;
        private volatile int gas;
    }

    public void updateData(UUID id, float nhietDo, float doAm, int tds, int gas){
        SensorData sensorData= new SensorData();
        sensorData.setNhiet_do(nhietDo);
        sensorData.setDo_am(doAm);
        sensorData.setTds(tds);
        sensorData.setGas(gas);
        userStotage.put(id,sensorData);
    }

    public SensorData getSensorDataByUserId(UUID id){
        return userStotage.get(id);
    }

    public ConcurrentHashMap<UUID,SensorData> getAllStorage(){
        return userStotage;
    }
}
