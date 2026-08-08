package com.example.backend.entities;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "DANH_MUC_VACCINE")
@Data
public class DanhMucVaccine {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private String ten_vaccine;
    private String phong_benh;
    private int ngay_tuoi;
    private String phuong_thuc;

    @OneToMany(mappedBy = "danhMucVaccine",cascade = CascadeType.ALL)
    @JsonIgnore
    private List<LichTiemThucTe> lichTiemThucTes;
}
