package com.example.backend.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.backend.entities.TieuChuanPhatTrien;
@Repository
public interface TieuChuanPhatTrienRepository extends JpaRepository<TieuChuanPhatTrien,Integer> {
    @Query(value = "SELECT * FROM tieu_chuan_phat_trien WHERE ngay_tuoi = :ngayTuoi", nativeQuery = true)
    TieuChuanPhatTrien findTieuChuanGannhatTrongQuaKhu(@Param("ngayTuoi") int ngayTuoi);

    @Query(value = "SELECT SUM(t.luong_thuc_an_tieu_chuan) FROM tieu_chuan_phat_trien t WHERE t.ngay_tuoi >= 1 AND t.ngay_tuoi <= :ngayTuoi", nativeQuery = true)
    int getTongLuongThucAnTichLuyDenNgay(@Param("ngayTuoi") int ngayTuoi);
}
