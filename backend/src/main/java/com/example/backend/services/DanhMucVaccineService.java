package com.example.backend.services;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.backend.entities.DanhMucVaccine;
import com.example.backend.repositories.DanhMucVaccineRepository;

@Service
public class DanhMucVaccineService {
    @Autowired
    private DanhMucVaccineRepository danhMucVaccineRepository;

    public List<DanhMucVaccine> getAllDanhMucVaccines(){
        return danhMucVaccineRepository.findAll();
    }

    public DanhMucVaccine createDanhMucVaccine(DanhMucVaccine danhMucVaccine){
        return danhMucVaccineRepository.save(danhMucVaccine);
    }
}
