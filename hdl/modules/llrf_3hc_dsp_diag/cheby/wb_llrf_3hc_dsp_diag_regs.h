#ifndef __CHEBY__WB_LLRF_3HC_DSP_DIAG_REGS__H__
#define __CHEBY__WB_LLRF_3HC_DSP_DIAG_REGS__H__

#define WB_LLRF_3HC_DSP_DIAG_REGS_SIZE 256 /* 0x100 */

/* REG ch */
#define WB_LLRF_3HC_DSP_DIAG_REGS_CH 0x0UL
#define WB_LLRF_3HC_DSP_DIAG_REGS_CH_SIZE 16 /* 0x10 */

/* REG rf_measurement */
#define WB_LLRF_3HC_DSP_DIAG_REGS_CH_RF_MEASUREMENT 0x0UL
#define ADDR_MASK_WB_LLRF_3HC_DSP_DIAG_REGS_CH_RF_MEASUREMENT 0xf0UL
#define ADDR_FMASK_WB_LLRF_3HC_DSP_DIAG_REGS_CH_RF_MEASUREMENT 0xf0UL
#define WB_LLRF_3HC_DSP_DIAG_REGS_CH_RF_MEASUREMENT_SIZE 16 /* 0x10 */

/* REG adc */
#define WB_LLRF_3HC_DSP_DIAG_REGS_CH_RF_MEASUREMENT_ADC 0x0UL

/* REG iq_demodulator */
#define WB_LLRF_3HC_DSP_DIAG_REGS_CH_RF_MEASUREMENT_IQ_DEMODULATOR 0x8UL
#define ADDR_MASK_WB_LLRF_3HC_DSP_DIAG_REGS_CH_RF_MEASUREMENT_IQ_DEMODULATOR 0x8UL
#define ADDR_FMASK_WB_LLRF_3HC_DSP_DIAG_REGS_CH_RF_MEASUREMENT_IQ_DEMODULATOR 0xf8UL
#define WB_LLRF_3HC_DSP_DIAG_REGS_CH_RF_MEASUREMENT_IQ_DEMODULATOR_SIZE 8 /* 0x8 */

/* REG i */
#define WB_LLRF_3HC_DSP_DIAG_REGS_CH_RF_MEASUREMENT_IQ_DEMODULATOR_I 0x8UL

/* REG q */
#define WB_LLRF_3HC_DSP_DIAG_REGS_CH_RF_MEASUREMENT_IQ_DEMODULATOR_Q 0xcUL

#ifndef __ASSEMBLER__
struct wb_llrf_3hc_dsp_diag_regs {
  /* [0x0]: REPEAT */
  struct ch {
    /* [0x0]: BLOCK */
    struct ch_rf_measurement {
      /* [0x0]: REG (ro) */
      uint32_t adc;

      /* padding to: 8 Bytes */
      uint32_t __padding_0[1];

      /* [0x8]: BLOCK */
      struct ch_rf_measurement_iq_demodulator {
        /* [0x0]: REG (ro) */
        uint32_t i;

        /* [0x4]: REG (ro) */
        uint32_t q;
      } iq_demodulator;
    } rf_measurement;
  } ch[10];

  /* padding to: 0 Bytes */
  uint32_t __padding_0[24];
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__WB_LLRF_3HC_DSP_DIAG_REGS__H__ */
