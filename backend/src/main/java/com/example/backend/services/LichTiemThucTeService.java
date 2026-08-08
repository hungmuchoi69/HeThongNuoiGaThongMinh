package com.example.backend.services;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.backend.entities.DanhMucVaccine;
import com.example.backend.entities.LichTiemThucTe;
import com.example.backend.entities.LuaGa;
import com.example.backend.repositories.DanhMucVaccineRepository;
import com.example.backend.repositories.LichTiemThucTeRepository;

@Service
public class LichTiemThucTeService {
    @Autowired
    private LichTiemThucTeRepository lichTiemThucTeRepository;

    @Autowired
    private DanhMucVaccineRepository danhMucVaccineRepository;

    @Transactional
    public void dongBoLichTiemLuaGa(LuaGa luaGa){
        List<DanhMucVaccine> danhMucVaccines = danhMucVaccineRepository.findAll();
        List<LichTiemThucTe> lichTiemThucTes = danhMucVaccines.stream().map(danhMuc ->{
            LocalDate ngayDuKien= luaGa.getNgay_nhap().plusDays(danhMuc.getNgay_tuoi()-1);
            LichTiemThucTe lichTiemThucTe=new LichTiemThucTe();
            lichTiemThucTe.setLuaGa(luaGa);
            lichTiemThucTe.setDanhMucVaccine(danhMuc);
            lichTiemThucTe.setTrang_thai("Chưa thực hiện");
            lichTiemThucTe.setNgay_du_kien(ngayDuKien);
            return lichTiemThucTe;
        }).collect(Collectors.toList());

        lichTiemThucTeRepository.saveAll(lichTiemThucTes);
    }

    public LichTiemThucTe updateLichTiemThucTe(int id, LichTiemThucTe lichTiemDetail){
        Optional<LichTiemThucTe> lt=lichTiemThucTeRepository.findById(id);
        if(lt.isPresent()){
            LichTiemThucTe existingLichTiemThucTe=lt.get();
            existingLichTiemThucTe.setNgay_thuc_hien(lichTiemDetail.getNgay_thuc_hien());
            existingLichTiemThucTe.setTrang_thai(lichTiemDetail.getTrang_thai());
            existingLichTiemThucTe.setGhi_chu(lichTiemDetail.getGhi_chu());
            return lichTiemThucTeRepository.save(existingLichTiemThucTe);
        }
        return null;
    }

    public List<LichTiemThucTe> getLichTiemThucTes(int idLuaGa){
        return lichTiemThucTeRepository.getLichTiemThucTeByLuaGa(idLuaGa);
    }
}
