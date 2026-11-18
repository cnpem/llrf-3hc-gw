//------------------------------------------------------------------------------
// Project     : ESS FPGA Framework
//------------------------------------------------------------------------------
// File        : sis8300ku_test_config.c
// Authors     : Christian Amstutz, Mehdi Mohammednezhad
// Created     : 2017-06-12
// Last update : 2022-03-21
// Platform    :
// Standard    :
//------------------------------------------------------------------------------
// Description : Main program running on the configuration MicroBlaze within the
//               ESS FPGA Framework
// Problems    :
//------------------------------------------------------------------------------
// Copyright (c) 2019 - 2020 European Spallation Source ERIC
//------------------------------------------------------------------------------

#include "sis8300ku.hpp"

#include "essffw.hpp"
#include "flash.hpp"
#include "xintc.h"
#include <xparameters.h>
#include <sleep.h>

#include "dwc8vm1_rsp/dwc8vm1.hpp"

#ifdef DEBUG
#include "xil_printf.h"
#endif

//#define TEST_WATCHDOG

essffw    m_essffw;
flash     m_flash;
sis8300ku m_sis8300ku;
DWC8VM1   m_rtm;

int main()
{
    m_essffw.ptr_ub_conf_reg->ub_sw_id = 0xABCD;  // SW ID for test projects
    m_essffw.ptr_ub_conf_reg->ub_sw_ver.major = 0;
    m_essffw.ptr_ub_conf_reg->ub_sw_ver.minor = 1;
    m_essffw.ptr_ub_conf_reg->ub_sw_ver.patch = 0;

    #ifdef DEBUG
	  xil_printf("\r\n");
	  xil_printf("---------------------------------------------\r\n");
	  xil_printf("Initializing peripherals on Struck SIS8300-KU board_id = 0x%x\r\n",m_sis8300ku.ptr_bsp_reg->bsp.id);
	  xil_printf("---------------------------------------------\r\n");
	  xil_printf("\r\n");
    #endif
    usleep(100000);
    m_essffw.init();
    m_flash.connect(&m_essffw.ip_context.flash_spi,&m_essffw.ip_context.watchdog_timer , &m_essffw.TransferInProgress, &m_essffw.ErrorCount);
    // Handle watchdog timer boot
    int watchdog_restart = m_essffw.detect_wdt_reset();
    m_essffw.watchdog_start();
    //m_essffw.watchdog_stop();
    if (watchdog_restart == 0)
    {
      #ifdef DEBUG
      xil_printf("\r\n");
      xil_printf("Setup Struck SIS8300-KU for test application\r\n");
      xil_printf("--------------------------------------------\r\n");
      #endif
    }

    if(m_flash.init())
      m_essffw.ptr_ub_conf_reg->ub_status.error_code |= ESSFFW_ERROR_FLASH_SETUP;
    if(m_sis8300ku.init())
      m_essffw.ptr_ub_conf_reg->ub_status.error_code |= ESSFFW_ERROR_BRD_SETUP;
    if (m_rtm.init(XPAR_RTM_I2C_CTRL_DEVICE_ID, &m_essffw.ip_context.intc_ctrl, XPAR_INTERRUPT_CTRL_RTM_I2C_CTRL_IIC2INTC_IRPT_INTR))
      m_essffw.ptr_ub_conf_reg->ub_status.error_code |= ESSFFW_ERROR_RTM_SETUP;

    m_essffw.boot_done();

    #ifdef DEBUG
    xil_printf("INFO: Entering progrom Loop\r\n");
	  #endif

    while(1)
    {
      #ifndef TEST_WATCHDOG
      m_essffw.kick_watchdog();
      #endif
      m_essffw.increase_heartbeat();
      usleep(10000);  // 10 ms to update the loop
      m_sis8300ku.update(m_essffw.ptr_ub_conf_reg);
      m_flash.chk_flashing_cmd();
      m_rtm.update_settings(m_essffw.ptr_ub_conf_reg);
      m_rtm.update_rtm_monitoring();
    }
    return 0;

}
