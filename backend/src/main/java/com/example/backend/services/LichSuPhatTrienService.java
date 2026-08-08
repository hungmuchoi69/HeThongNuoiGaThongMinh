package com.example.backend.services;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.backend.entities.LichSuPhatTrien;
import com.example.backend.repositories.LichSuPhatTrienRepository;

@Service
public class LichSuPhatTrienService {
    @Autowired
    private LichSuPhatTrienRepository lichSuPhatTrienRepository;

    public List<LichSuPhatTrien> getAllLichSuPhatTriens(int idLuaGa){
        return lichSuPhatTrienRepository.getLichSuPhatTrienByLuaGa(idLuaGa);
    }

    public LichSuPhatTrien createLichSuPhatTrien(LichSuPhatTrien lichSuPhatTrien){
        return lichSuPhatTrienRepository.save(lichSuPhatTrien);
    }
}
