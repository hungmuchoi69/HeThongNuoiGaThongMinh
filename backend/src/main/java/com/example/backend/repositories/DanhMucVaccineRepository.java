package com.example.backend.repositories;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.backend.entities.DanhMucVaccine;
@Repository
public interface DanhMucVaccineRepository extends JpaRepository<DanhMucVaccine,Integer>{
    @Query(value = "SELECT * FROM danh_muc_vaccine WHERE ngay_tuoi = :nt", nativeQuery = true)
    List<DanhMucVaccine> findDanhMucVaccinesByNgayTuoi(@Param("nt") int ngayTuoi);
}
