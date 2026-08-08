package com.example.backend.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.backend.entities.LoaiChiPhi;

@Repository
public interface LoaiChiPhiRepository extends JpaRepository<LoaiChiPhi,Integer> {
    
}
