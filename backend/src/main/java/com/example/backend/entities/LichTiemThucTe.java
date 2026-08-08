package com.example.backend.entities;

import java.time.LocalDate;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Data;
@Entity
@Table(name = "LICH_TIEM_THUC_TE")
@Data
public class LichTiemThucTe {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private LocalDate ngay_du_kien;
    private LocalDate ngay_thuc_hien;
    private String trang_thai;
    private String ghi_chu;
    @ManyToOne
    @JoinColumn(name = "id_vaccine")
    private DanhMucVaccine danhMucVaccine;

    @ManyToOne
    @JoinColumn(name = "id_lua_ga")
    private LuaGa luaGa;
}
