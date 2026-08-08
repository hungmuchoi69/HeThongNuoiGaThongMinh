package com.example.backend.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.backend.entities.DanhMucVaccine;
import com.example.backend.services.DanhMucVaccineService;

@RestController
@RequestMapping("/api/DanhMucVaccine")
public class DanhMucVaccineController {
    @Autowired
    private DanhMucVaccineService danhMucVaccineService;

    @GetMapping
    public List<DanhMucVaccine> getAllDanhMucVaccines(){
        return danhMucVaccineService.getAllDanhMucVaccines();
    }

    @PostMapping
    public DanhMucVaccine createDanhMucVaccine(@RequestBody DanhMucVaccine danhMucVaccine){
        return danhMucVaccineService.createDanhMucVaccine(danhMucVaccine);
    }
}
