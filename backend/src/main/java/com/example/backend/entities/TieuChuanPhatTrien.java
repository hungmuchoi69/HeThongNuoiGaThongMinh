package com.example.backend.entities;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "TIEU_CHUAN_PHAT_TRIEN")
@Data
public class TieuChuanPhatTrien {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private int ngay_tuoi;
    private float trong_luong_tc;
    private float luong_thuc_an_tieu_chuan;
    private float nhiet_do_toi_thieu;
    private float nhiet_do_toi_da;
    private float do_am_tc;
}
