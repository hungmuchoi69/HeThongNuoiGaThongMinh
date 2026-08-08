package com.example.backend.services;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.backend.entities.CamBienHomNay;
import com.example.backend.repositories.CamBienHomNayRepository;

@Service
public class CamBienHomNayService {
    @Autowired
    private CamBienHomNayRepository camBienHomNayRepository;

    public List<CamBienHomNay> getAllCamBienHomNaysByIdLuaGa(int idLuaGa){
        return camBienHomNayRepository.getCamBienHomNayByLuaGa(idLuaGa);
    }

    public CamBienHomNay createCamBienHomNay(CamBienHomNay camBienHomNay){
        return camBienHomNayRepository.save(camBienHomNay);
    }
}
