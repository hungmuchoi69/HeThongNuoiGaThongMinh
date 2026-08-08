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
@Table(name = "CHI_PHI_CHAN_NUOI")
@Data
public class ChiPhiChanNuoi {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private LocalDate ngay_chi_tieu;
    private int so_tien;
    private String ghi_chu;
    @ManyToOne
    @JoinColumn(name = "id_loai_chi_phi")
    private LoaiChiPhi loaiChiPhi;

    @ManyToOne
    @JoinColumn(name = "id_lua_ga")
    private LuaGa luaGa;
}
