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
@Table(name = "LOAI_CHI_PHI")
@Data
public class LoaiChiPhi {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private String ten_loai;
    private String mo_ta;
    @OneToMany(mappedBy = "loaiChiPhi", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<ChiPhiChanNuoi> chiPhiChanNuois;
}
