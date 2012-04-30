#ifndef UQUAD_KALMAN_H
#define UQUAD_KALMAN_H
#include <uquad_aux_math.h>
#include <imu_comm.h>
#include <uquad_gps_comm.h>

#define KALMAN_ROWS_H_GPS 12
#define KALMAN_ROWS_H     10
#define KALMAN_GPS_SIZE   6

/**
 * Kalman struct description (matches uquad_types.h):
 *
 * x_hat: State vector
 *    [x         ] - m
 *    [y         ] - m
 *    [z         ] - m
 *    [psi/roll  ] - rad
 *    [phi/pitch ] - rad
 *    [theta/yaw ] - rad
 *    [vqx       ] - m/s
 *    [vqy       ] - m/s
 *    [vqz       ] - m/s
 *    [wqx       ] - rad/s
 *    [wqy       ] - rad/s
 *    [wqz       ] - rad/s
 * Acc bias estimation (iif KALMAN_BIAS)
 *    [abx       ] - m/s^2
 *    [aby       ] - m/s^2
 *    [abz       ] - m/s^2
 *
 * T: Time since last sample, in us
 * weight: Weight of the cuadcopter - kg
 *
 */
typedef struct kalman_io {
    uquad_mat_t *x_hat;
    uquad_mat_t *u;
    uquad_mat_t *z;
    uquad_mat_t *z_gps;
    double T;
    double weight;
    uquad_mat_t *x_;
    uquad_mat_t *R;
    uquad_mat_t *Q;
    uquad_mat_t *P;
    uquad_mat_t *P_;
    uquad_mat_t *R_imu_gps;
} kalman_io_t;

int uquad_kalman(kalman_io_t * kalman_io_data, uquad_mat_t* w, imu_data_t* data, double T, double weight, gps_comm_data_t *gps_i_data);
int uquad_kalman_gps(kalman_io_t* kalman_io_data, gps_comm_data_t* gps_i_data);
kalman_io_t* kalman_init();
void kalman_deinit(kalman_io_t *kalman_io_data);

/**
 * Saves Kalman noise settings to file
 *
 * @param kalman_io_data
 * @param output log file, or NULL for stdout.
 *
 * @return error code
 */
int kalman_dump(kalman_io_t *kalman_io_data, FILE *output);

#endif
