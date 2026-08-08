package com.example.backend.repositories;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.example.backend.entities.CamBienHomNay;

@Repository
public interface CamBienHomNayRepository extends JpaRepository<CamBienHomNay,Integer> {
    @Query(value = "SELECT AVG(nhiet_do) as avgTemp, AVG(do_am) as avgHumi, AVG(tds) as avgTds, AVG(gas) as avgGas " +
                   "FROM cam_bien_hom_nay " +
                   "WHERE logged_at BETWEEN :start AND :end and id_lua_ga =:idLuaga", nativeQuery = true)
    CamBienAverage getDailyAverage(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end, @Param("idLuaGa") int id);

    @Query(value = "SELECT * FROM cam_bien_hom_nay " +
                   "WHERE id_lua_ga = :idLuaGa", 
                   nativeQuery = true)
    List<CamBienHomNay> getCamBienHomNayByLuaGa(@Param("idLuaGa") int idLuaGa);

    @Modifying
    @Transactional
    @Query(value = "DELETE FROM cam_bien_hom_nay", 
                   nativeQuery = true)
    int deleteOldSensorData();
}
