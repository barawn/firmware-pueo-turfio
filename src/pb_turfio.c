/*
 * This is not C, it's the pseudo-C used
 * with https://github.com/barawn/picoblaze-utils
 *
 */

#define PB_TURFIO_VERSION 3

// We use the stock UART/COBS decoder, but we don't
// buffer except at the UART level.
//
// We also use the half-code/half-buffer option
// to give ourselves 128 bytes of buffer space
// and split it into a 2x 64 byte packet buffer.
// We receive packets in an ISR and when complete
// we mark a bit in regbank A's sE register.
//
// We're a little stupider than the SURF so
// if you try to send a packet that's too long
// we'll throw an error back.

// We literally just throw away every packet
// that contains a COBS decode error in it.

// I'm still trying to figure out how to handle the
// housekeeping. We're currently at 312/960.
// If I add an additional 128 byte buffer that's now
// 312/896.
// Yeah, I can probably fit it. There's more optimization
// for space that can be done too.

// First need to test the UART though.

// fifoStatus contains a bitset that indicates
// the status of the dual buffer.
#define fifoStatus sE
// fifoCurrent contains the CURRENT buffer bitmask in ISR.
#define fifoCurrent sD

#define fifoIn s0
#define fifoPtr s1
#define fifoTmp s2
#define fifoTmp2 s3

#define curPacket s0
#define curPtr s1
#define curTmp s2
#define curTmp2 s3
#define ourID sF
// our scratch regs are s4-sD

#define FIFO_COMPLETE_0 0x01
#define FIFO_COMPLETE_1 0x02
#define FIFO_TOGGLE 0x03
#define HSK_RESET 0x80

#define FIFO_PTR_MASK 0x3F

#define REGBANK_USER 0
#define REGBANK_ISR 1

#define UART_STATUS_ERR 0x01
#define UART_STATUS_LAST 0x02

// These are all mapped outputk as well
#define PACKET_BASE  0x80
#define PACKET_SRC   0x80
#define PACKET_SRC_K 0x00
#define PACKET_DST   0x81
#define PACKET_DST_K 0x01
#define PACKET_CMD   0x82
#define PACKET_CMD_K 0x02
#define PACKET_LEN   0x83
#define PACKET_LEN_K 0x03
#define PACKET_DATA  0x84
#define PACKET_DATA_K 0x04
// we also have PACKET_DATA_K+1 through PACKET_DATA_K+3

// housekeeping base
// SURFs are in multiples of 8 (4x2 shorts each)
#define HSK_BASE 0xC0
// TURFIO is therefore at 56 (F8)
#define TURFIO_BASE 0xF8
// easy options for looping (VIN/VOUT/IOUT/TEMP)
#define SURF_BASE_VIN 0xC0
#define SURF_BASE_VOUT 0xC2
#define SURF_BASE_IOUT 0xC4
#define SURF_BASE_TEMP 0xC6
// loop constants
#define SURF_VIN_MAX  0xF8
#define SURF_IOUT_MAX 0xFC
#define SURF_TEMP_MAX 0xFE
#define SURF_VOLT_INC 4
#define SURF_CURR_INC 6
#define SURF_TEMP_INC 6

#define MAX_LENGTH 59

// this is also mapped outputk
#define UART_TX      0x8
#define UART_TX_LAST 0x9
#define UART_RX      0xA
#define UART_STATUS  0xB
#define BUFFER_CTRL  0xB

// as are these
#define I2C_input_port   0xC
#define I2C_output_clk   0xD
#define I2C_output_data  0xE
#define I2C_output_both  0xF
#define TEMP_0 0xE
#define TEMP_1 0xF

// our housekeeping ID (conf pin read)
#define OUR_ID 0x10
// general control port (read/write)
// bit 0 : housekeeping buffer
// bit 1 : disable (probably)
#define GC_PORT 0x11
// bitmask
#define HSK_BUF_BIT 0x1

// I2C bit defines
// this is swapped from turfio-y stuff
// b/c it's way faster
#define I2C_clk 0x02
#define I2C_data 0x01
#define I2C_init() \
  outputk( I2C_output_both, (I2C_clk | I2C_data) )

#define I2C_data_Z() \
  outputk( I2C_output_data, I2C_data)

#define I2C_data_Low() \
  outputk( I2C_output_data, 0 )

#define I2C_clk_Low() \
  outputk( I2C_output_clk, 0)

#define I2C_clk_Z() \
  outputk( I2C_output_clk, I2C_clk)

// state machine stuff
// we use several bytes for the state machine
// 0x10 defines the general state
#define state_IDLE_WAIT      0x00
#define state_SURF_CHECK     0x01
#define state_SURF_WRITE_REG 0x02
#define state_SURF_READ_REG  0x03
#define state_TURFIO         0x04
#define state_PMBUS          0x05
// 0x11 defines what stage we're in
#define stage_SURF_VIN       0x00
#define stage_SURF_VOUT      0x01
#define stage_SURF_IOUT      0x02
#define stage_SURF_TEMP      0x03
#define stage_TURFIO_I2C     0x04
#define stage_TURFIO_TEMP    0x05

#define SURFSTAGE_BASE 0x34
#define SURFSTAGE_LAST 0x37

// 0x12 defines what device we're accessing.
// This is the order we do it in.
// Yes, it's backwards.
#define device_TURFIO        0x00
#define device_SURF7         0x40
#define device_SURF6         0x20
#define device_SURF5         0x10
#define device_SURF4         0x08
#define device_SURF3         0x04
#define device_SURF2         0x02
#define device_SURF1         0x01







// SCRATCHPADS - these values are ALL USED
#define scratch_PRESENT     0x00
// statistics
#define scratch_RXCOUNT     0x08
#define scratch_TXCOUNT     0x09
#define scratch_ERRCOUNT    0x0A
#define scratch_DROPCOUNT   0x0B
#define scratch_SKIPCOUNT   0x0C

// state machine
#define scratch_STATE       0x10
#define scratch_STAGE       0x11
#define scratch_DEVICE      0x12
#define scratch_TIMER_LOW   0x13
#define scratch_TIMER_HIGH  0x14
// PMBus buffer.
// here's how PMBus works for an I2C WRITE
// housekeeping sends: 0x80 0xD9 (power cycle addr 0x40)
// parse_housekeeping first checks if *0x17 is zero - returns 0 if not
// then stores
// *(0x18) = 0x80 *(0x19) = 0xD9 *(0x17) = 2 *(0x16) = 0
// and returns 2 (bytes stored in buffer)
// update_housekeeping in WAIT_IDLE sees non-zero *(0x17)
// reads *(0x18) - sees zero bit 0
// writes 0x80, sees ack, writes 0x00 to *0x18 (if NACK stores 0x1)
// writes 0xD9, sees ack, writes 0x00 to *0x19 (if NACK stores 0x1)
// writes 2 to *(0x16) and 0 to *(0x17)
//
// housekeeping then receives another PMBus command that is EMPTY DATA (rd)
// it checks *0x16, sees 2
// reads *(0x18) 0x00, *(0x19) 0x00, sends those two bytes
// writes *0x16 = 0x00
// if *0x16 is empty it returns empty
//
// a read works similar except the housekeeping command sends e.g.
// 0x81 0x00 0x00
// parse_housekeeping writes *(0x18) = 0x81 *(0x19) = 0x0, *(0x1A) = 0x0
// *0x17 = 3, *0x16 = 0
// update_housekeeping in WAIT_IDLE sees non-zero *0x17
// reads *0x18, sees nonzero bit 0
// writes 0x80, sees ack, writes 0x00 to *0x18
// reads 8 bits, writes value to *0x19
// reads 8 bits, writes value to *0x1A
// writes 3 to *0x16 and 0 to *0x17
//
// SO COMPLICATED
#define scratch_PMBus_RPtr  0x16
#define scratch_PMBus_WPtr  0x17
#define scratch_PMBus_BASE  0x18

// this is where the I2C user buffer stuff is.
// I2C user data is read/written in REVERSE to autodetect the length.
#define scratch_I2CBUFFER   0x20
#define scratch_I2CBUFFER1  0x21
#define scratch_I2CBUFFER2  0x22
#define scratch_I2CBUFFER3  0x23
#define scratch_I2CBUFFER4  0x24
#define scratch_I2CBUFFER5  0x25
#define scratch_I2CBUFFER6  0x26
#define scratch_I2CBUFFER7  0x27

///////////////////////////////////////////////
//  MAGIC CONSTANT SECTION                   //
///////////////////////////////////////////////
// These get automatically loaded by the     //
// scratchpad init attributes.               //
///////////////////////////////////////////////

// PMBus registers for SURF
#define scratch_SURFVIN     0x34
#define scratch_SURFVOUT    0x35
#define scratch_SURFIOUT    0x36
#define scratch_SURFTEMP    0x37
// I2C addresses for everyone
#define scratch_SURF1       0x38
#define scratch_SURF2       0x39
#define scratch_SURF3       0x3A
#define scratch_SURF4       0x3B
#define scratch_SURF5       0x3C
#define scratch_SURF6       0x3D
#define scratch_SURF7       0x3E
#define scratch_TURFIO      0x3F

// constants used in the loops
#define I2C_ADDR_SP_START   (scratch_SURF1)
#define I2C_ADDR_SP_STOP    (scratch_TURFIO)
#define I2C_SP_BUFFERSTOP   (scratch_I2CBUFFER-1)
// just constant
#define I2C_ADDR_TURFIO     (0x48 << 1)

// this is an output/outputk port which
// indicates which buffer we're working on.
// It knows what bank we're using,
// so it properly sets either the ISR
// buffer or the main user buffer.

#define ePingPong 0x00
#define eStatistics 0x0F
#define eTemps 0x10
#define eVolts 0x11
#define eIdentify 0x12
#define eCurrents 0x13
#define eEnable 0xC0
#define ePMBus 0xC1

// always 5 bytes
#define Statistics_LENGTH 5
// always 2 bytes
#define Identify_LENGTH 2
// always 16 bytes
#define Temps_LENGTH 16
// always 7x4 + 2 = 30 bytes
#define Volts_LENGTH 30
// always 16 bytes
#define Currents_LENGTH 16
// always 1 byte
#define Enable_LENGTH 1

// we steal 256 bytes for the buffer
// this is 128 instructions
// this means we have 1024-64 max so we're at 37F
bool_t isr_serial(void) __attribute__ ((interrupt (0x37F)));

bool_t isr_serial(void)
{
  // should encode this as a function as well
  psm("star sE, sE");
  regbank(REGBANK_ISR);
  // we don't have to worry about overflows or clashing
  // with userspace here: that happens at the end of
  // packet processing when we swap to the other half-buffer.
  // if it's still busy, we disable interrupts after swapping.
  input(UART_RX, &fifoIn);
  input(UART_STATUS, &fifoTmp);
  // if there was a tuser error, toss the packet
  if (fifoTmp & UART_STATUS_ERR) {
    fifoPtr = 0;
    regbank(REGBANK_USER);
    return 1;
  }
  // store the data
  output(fifoPtr, fifoIn);
  // figure out if we're last
  if (fifoTmp & UART_STATUS_LAST) {
    fifoPtr = PACKET_BASE;    
    fifoStatus |= fifoCurrent;
    psm("star sE, sE");
    fifoCurrent ^= FIFO_TOGGLE;
    output(BUFFER_CTRL, fifoCurrent);
    if (fifoStatus & fifoCurrent) {
      regbank(REGBANK_USER);
      return 0;
    } else {
      regbank(REGBANK_USER);
      return 1;
    }
  } else {
    // overflow test. super-ultra branch-free hack.
    //
    // This whole thing is the equivalent of
    // fifoPtr += 1
    // if (!(fifoPtr < 0xC0)) fifoPtr -= 1;
    fifoPtr += 1;
    // if we overflow, fifoPtr goes from BF to C0.
    // so we can test if fifoPtr is less than C0.
    // if fifoPtr is not less than C0, C will NOT
    // be set: otherwise it will. We can then
    // 'fix' fifoPtr by adding FF with carry:
    // if carry is set, it will do nothing,
    // otherwise it'll jump back to BF.
    psm("compare %1, %2", fifoPtr, 0xC0);
    psm("addcy %1, %2", fifoPtr, 0xFF);
    // e.g. if fifoPtr is 80:
    // 80 +1 = 81
    // compare 81, 0xC0 (C=1, Z=0)
    // addcy 81, FF (C=1) = 81
    // and if fifoPtr is BF:
    // BF +1 = C0
    // compare C0, C0 (C=0, Z=0)
    // addcy C0, FF (C=0) = BF
    // This will likely stay a psm hack? Probably
    // the only way to recognize this is if you've got
    // an if/endif with the only operation in the middle
    // being add/subtract 1. Technically you could also
    // have an if/else/endif grouping with the differences
    // being off by one.
    regbank(REGBANK_USER);
    return 1;
  }      
}

// ok, this is stupid. I'm going to end up using these
// a hundred times so I should probably embed them.
// 
// 10, 11, 12, 40, 41, 42, 46
void init() {
  outputk( BUFFER_CTRL, HSK_RESET );
  I2C_init();
  // first, probe-y probe-y. no one's sending us stuff straight
  // at reset anyway.
  // we can use curPacket/curPtr at start

  // this is ultrasleaze. we have to start one before the beginning
  // because we need the increment to happen after the test
  // b/c it will clear carry.
  curPtr = I2C_ADDR_SP_START-1;
  curPacket = 0x80;
  do {
    curPtr++;
    fetch(curPtr, &sA);
    I2C_test();
    // sra will take in C to the top bit
    // and pop out the value from the bottom bit.
    // this means that when C ends up being
    // set after this, we've looped through
    // this eight times.
    psm("sra %1", curPacket);
  } while (!C);
  // we actually got MISSING not PRESENT so flip the bits
  curPacket ^= 0xFF;
  // OUTPUT THIS TO SOMETHING FOR WISHBONE VISIBILITY HERE
  // we DO NOT CARE about the TURFIO anymore, drop it!
  curPacket &= 0x7F;
  store(scratch_PRESENT, curPacket);
  // just ALWAYS do this, it doesn't matter, it'll always be there
  I2C_turfio_initialize();
  // now we also need to do I2C initializations
  curPtr = scratch_SURF1;
  do {
    if (curPacket & 0x1) {
      fetch(curPtr, &sA);
      I2C_surf_initialize();      
    }
    curPtr++;
    curPacket >>= 1;
  } while (!Z);

  // now we initialize the hsk buffer
  input(GC_PORT, &curTmp);
  curTmp &= ~HSK_BUF_BIT;
  output(GC_PORT, curTmp);

  // and the PMBus buffer
  curTmp = 0;
  store(scratch_PMBus_WPtr, curTmp);
  store(scratch_PMBus_RPtr, curTmp);
  
  // and the state machine
  // timer starts at 0 which begins
  // the readout right away.
  // originally this was huge
  // but the full overhead is HUGE since in the
  // update thread we do idle last
  // overall each pass through IDLE_WAIT takes
  // like nearly 700 ns or so
  
  curTmp = 0;
  store(scratch_TIMER_LOW, curTmp);
  store(scratch_TIMER_HIGH, curTmp);
  store(scratch_DEVICE, curTmp);
  store(scratch_STATE, curTmp);
  
  // now initialize housekeeping stuff
  regbank(REGBANK_ISR);
  // pulls housekeeping out of reset
  outputk(BUFFER_CTRL, FIFO_COMPLETE_0);
  fifoPtr = PACKET_BASE;
  fifoStatus = 0;
  fifoCurrent = FIFO_COMPLETE_0;
  
  regbank(REGBANK_USER);
  fifoStatus = 0;
  curPacket = FIFO_COMPLETE_0;
  curPtr = 0;
  input(OUR_ID, &ourID);
  enable_interrupt();
  // yupyup we're done
}

void loop() {
  handle_serial();
  update_housekeeping();
}


//////////////////////////////////////////////////////////////
//                I2C MONITORING LOOP                       //
//////////////////////////////////////////////////////////////
void update_housekeeping() {
  fetch(scratch_STATE, &curTmp);

  // pblaze-cc currently can't handle a switch statement:
  // this is the cheapest implementation of a switch table
  // (compare/jump pairs).
  if (curTmp == state_SURF_CHECK) goto SURF_CHECK;
  if (curTmp == state_SURF_WRITE_REG) goto SURF_WRITE_REG;
  if (curTmp == state_SURF_READ_REG) goto SURF_READ_REG;
  if (curTmp == state_TURFIO) goto TURFIO;
  // default is IDLE_WAIT. PMBus isn't a real state
  // just a goto
 IDLE_WAIT:
  fetch(scratch_PMBus_WPtr, &curTmp);
  if (curTmp != 0) goto PMBUS;
  // next decrement timer
  fetch(scratch_TIMER_LOW, &curTmp);
  fetch(scratch_TIMER_HIGH, &curTmp2);
  curTmp2.curTmp--;
  store(scratch_TIMER_LOW, curTmp);
  store(scratch_TIMER_HIGH, curTmp2);
  if (!C) return;
  // the I2C upper timer loop is stored in hwbuild
  // so it can be shortened. The operational loop
  // adds something like a ~800 us delay between devices
  // leading to something like a 100 Hz update rate.
  // Simulation is more like 100 us.
  curTmp = 0x80;
  psm("hwbuild %1", curTmp2);
  store(scratch_TIMER_LOW, curTmp);
  store(scratch_TIMER_HIGH, curTmp2);
  
  // timer expired, do next device
  fetch(scratch_DEVICE, &curTmp);
  // if turfio go to turfio mode
  if (curTmp == device_TURFIO) {
    curTmp = state_TURFIO;
    curTmp2 = stage_TURFIO_I2C;
  } else {
    curTmp = state_SURF_CHECK;
    curTmp2 = stage_SURF_VIN;
  }
  store(scratch_STATE, curTmp);
  store(scratch_STAGE, curTmp2);
  return;
 SURF_CHECK:
  fetch(scratch_DEVICE, &curTmp);
  fetch(scratch_PRESENT, &curTmp2);
  if (!(curTmp & curTmp2)) goto hskNextDevice;
 SURF_WRITE_REG:
  // what stage are we in
  fetch(scratch_STAGE, &curTmp);
  // move to the base of the scratchpad containing register number
  curTmp += SURFSTAGE_BASE;
  // fetch the register number
  fetch(curTmp, &curTmp);
  // store it as the second byte we write
  store(scratch_I2CBUFFER, curTmp);
  // stores device address in curTmp
  hskGetDeviceAddress();
  // store it as the first byte we write
  store(scratch_I2CBUFFER1, curTmp);

  // execute the transaction
  I2C_start();
  s4 = scratch_I2CBUFFER1;
  I2C_user_tx_process();
  I2C_stop();

  // move to read state and exit
  curTmp = state_SURF_READ_REG;
  store(scratch_STATE, curTmp);  
  return;
 SURF_READ_REG:
  // what device are we
  hskGetDeviceAddress();

  // read 2 bytes
  store(scratch_I2CBUFFER1, curTmp);
  s6 = scratch_I2CBUFFER1;
  I2C_read();

  // calc the pointer
  // the pointer calc is
  // SURF_BASE_VIN + (stage*2) + (device*8)
  s6 = SURF_BASE_VIN;
  fetch(scratch_STAGE, &s7);
  s7 <<= 1;
  s6 += s7;
  fetch(scratch_DEVICE, &curTmp);
  hskCountDevice();
  curTmp2 <<= 1;
  curTmp2 <<= 1;
  curTmp2 <<= 1;
  s6 += curTmp2;
  // we save ALL of our data MSB, LSB since that's
  // how we're going to transmit it.
  // fetch LSB
  fetch(scratch_I2CBUFFER1, &s4);
  // fetch MSB
  fetch(scratch_I2CBUFFER, &s5);
  // store MSB
  output(s6, s5);
  s6 += 1;
  // store LSB
  output(s6, s4);
  // increment stage, jump device if we need to
  fetch(scratch_STAGE, &s7);
  s7++;
  if (s7 == stage_TURFIO_I2C) goto hskNextDevice;
  store(scratch_STAGE, s7);
  curTmp = state_SURF_WRITE_REG;
  store(scratch_STATE, curTmp);
  // and done. we only pause between devices,
  // but we pause between each I2C transaction.
  return;
 TURFIO:
  fetch(scratch_STAGE, &curTmp);
  if (curTmp == stage_TURFIO_I2C) {
    // read 3 bytes from TURFIO swap controller
    s4 = I2C_ADDR_TURFIO;    
    store(scratch_I2CBUFFER1, s4);
    s6 = scratch_I2CBUFFER2;
    I2C_read();
    // get the data:
    // s4 = voltage
    // s5 = current
    // s6 = v (MSBs) i (LSBs)
    fetch(scratch_I2CBUFFER2, &s4);
    fetch(scratch_I2CBUFFER1, &s5);
    fetch(scratch_I2CBUFFER, &s6);
    // convert into sane values

    // utter magic shit
    // we have
    // VVVV_VVVV s4
    // IIII_IIII s5
    // vvvv_iiii s6
    // step 1: imagine this as
    // s7        s4        s6        s5
    // 0000_0000 VVVV_VVVV vvvv_iiii IIII_IIII
    // first s7.s4.s6 <<= 4;
    // 0000_VVVV VVVV_vvvv iiii_0000 IIII_IIII
    // step 2: now imagine this as
    // s7        s4        s5        s6
    // 0000_VVVV VVVV_vvvv IIII_IIII iiii_0000
    // s5.s6 >>= 4
    // to give
    // 0000_VVVV VVVV_vvvv 0000_IIII IIII_iiii
    // to simplify the loops, before step 1
    // set s7 as 0001_0000 (0x08)
    // and before step2 OR s6 with 0000_1000
    // and do the shifts until the bit falls out
    s7 = 0x10;
    do {
      s7.s4.s6 <<= 1;
    } while (!C);
    s6 |= 0x08;
    do {
      s5.s6 >>= 1;
    } while (!C);
  
    // s7.s4 contains voltages
    // s5.s6 contains currents
    // TURFIO_BASE/TURFIO_BASE+1 = voltage
    // TURFIO_BASE+2/TURFIO_BASE+3 = current
    // we always store MSB/LSB
    output(TURFIO_BASE, s7);
    output(TURFIO_BASE+1, s4);
    output(TURFIO_BASE+2, s5);
    output(TURFIO_BASE+3, s6);
    // move to the temperature stage
    curTmp = stage_TURFIO_TEMP;
    store(scratch_STAGE, curTmp);
    return;
  }
  // temp0 is LSB, we need to read it first
  input(TEMP_0, &curTmp);
  output(TURFIO_BASE+5, curTmp);
  input(TEMP_1, &curTmp);
  output(TURFIO_BASE+4, curTmp);
  // done with TURFIO, change device
  goto hskNextDevice;
 PMBUS:
  // PMBus stuff only happens in IDLE_WAIT
  // and housekeeping stuff better not be
  // stupid. It shouldn't be an issue because
  // if we're in here we can't be in here
  // realistically longer than a packet.

  // start with the address
  fetch(scratch_PMBus_BASE, &curTmp2);
  if (curTmp2 & 0x1) {
    // this is a read
    // I2C_read() wants address stored in scratch_I2CBUFFER1 and
    // pointer in s6
    store(scratch_I2CBUFFER1, curTmp2);
    // curTmp is number of bytes but it includes header
    s6 = curTmp;
    // s6 is supposed to be the start pointer, moving backwards
    s6 += (scratch_I2CBUFFER-1);
    I2C_read();
    // check C to store the ack
    curTmp = 0;

    // fetch the number of bytes we wrote
    fetch(scratch_PMBus_WPtr, &s4);
    // and null it. we do this here b/c
    // we've got a zero register (curTmp)
    store(scratch_PMBus_WPtr, curTmp);
    // now save the NAK/ACK
    psm("sla %1", curTmp);
    store(scratch_PMBus_BASE, curTmp);    
    // and update the RPtr
    store(scratch_PMBus_RPtr, s4);

    // ok, the only thing left is to memcpy.
    // WPtr is 0 and RPtr contains # of bytes.

    // from nbytes+scratch_I2CBUFFER-2 downto scratch_I2CBUFFER
    // to scratch_PMBus_BASE+1
    // but there's a chance we might already be done
    s4 += (scratch_I2CBUFFER-2);
    // s4 is the start pointer
    s5 = scratch_PMBus_BASE+1;
    // if *scratch_PMBus_WPtr is 1, this will be skipped
    while (!(s4 < scratch_I2CBUFFER)) {
      fetch(s4, &curTmp);
      store(s5, curTmp);
      s4--;
      s5++;
    }
    return;
  } else {
    // this is a write
    //
    // curTmp contains # of bytes to write including
    // address. e.g. for just the address it's just 0x01
    // we want to copy from
    // scratch_PMBus_BASE[0:(curTmp-1)]
    // to
    // scratch_I2CBUFFER+(curTmp-1) downto scratch_I2CBUFFER
    s4 = curTmp;  // e.g. it might be 1
    s4 += scratch_I2CBUFFER-1; // if it's 1, this is just scratch_I2CBUFFER
    // this now points one past the end
    curTmp += scratch_PMBus_BASE;
    s5 = scratch_PMBus_BASE;
    s6 = s4;
    do {
      fetch(s5, &curTmp2);
      store(s6, curTmp2);
      s5++;
      s6--;
    } while (s5 != curTmp);
    I2C_start();
    I2C_user_tx_process();
    I2C_stop();
    s4 = 0;
    // capture NAK (carry flag)
    psm("sla %1", s4);
    // and finish. We only write
    // the first byte, we don't care
    // about the others.
    store(scratch_PMBus_BASE, s4);
    fetch(scratch_PMBus_WPtr, &s4);
    store(scratch_PMBus_RPtr, s4);
    s4 = 0;
    store(scratch_PMBus_WPtr, s4);
    return;
  }
 hskNextDevice:
  fetch(scratch_DEVICE, &curTmp);
  if (curTmp == 0) curTmp = 0x80;    
  // this is now either 40/20/10/08/04/02/01 or 00
  curTmp >>= 1;
  // these don't touch Z
  store(scratch_DEVICE, curTmp);
  curTmp2 = state_IDLE_WAIT;
  store(scratch_STATE, curTmp2);
  // if this is Z we're in TURFIO
  // mode, which means we've wrapped
  // around. Otherwise return. 
  if (!Z) return;
  // flip the buffer
  input(GC_PORT, &curTmp);
  curTmp ^= 0x1;
  output(GC_PORT, curTmp);
}

void hskCountDevice() {
  curTmp2 = 0xFF;
  do {
    curTmp2++;
    psm("sr0 %1", curTmp);
  } while (!C);
}

void hskGetDeviceAddress() {
  // what device are we
  fetch(scratch_DEVICE, &curTmp);
  hskCountDevice();
  curTmp2 += (I2C_ADDR_SP_START);
  // get the address
  fetch(curTmp2, &curTmp);
}

void handle_serial() {
  if (!(curPacket & fifoStatus)) {
    // nothin' to do
    return;
  }
  parse_serial();
  // this might seem a little dangerous
  // but we know that fifoStatus had curPacket set
  // above.
  fifoStatus ^= curPacket;
  curPacket ^= FIFO_TOGGLE;
  // moron, this needs to actually update outside too
  output(BUFFER_CTRL, curPacket);
  
  // we always enable interrupts at the end,
  // in case the ISR panicked and shut itself off.
  enable_interrupt();  
}

// this is so insane
void parse_serial() {
  // is it for us?
  input(PACKET_DST, &curTmp);
  if (curTmp != ourID) goto skippedPacket;
  // get length
  input(PACKET_LEN, &s4);
  // the biggest packet WE can handle would have a payload
  // length of 59
  if (s4 > MAX_LENGTH) goto droppedPacket;

  // verify data checksum
  s5 = 0;
  // set curPtr to checksum byte by adding length + PACKET_DATA
  curPtr = s4;
  curPtr += PACKET_DATA;
  // now add everything until we've hit PACKET_DATA
  // overflows naturally get dropped.
  do {
    input(curPtr, &s6);
    s5 += s6;
    curPtr--;
  } while (curPtr != (PACKET_DATA-1));

  // NOPE NO NO NO - BAD CHECKSUM
  if (s5 != 0) goto errorPacket;

  // fetch cmd
  input(PACKET_CMD, &curTmp);
  // TYPE DECODING
  // THE _ONLY_ COMMANDS WE HANDLE ARE - the common ones:
  // ePingPong
  // eStatistics
  // eTemps
  // eVolts
  // eIdentify
  // eCurrents
  // and then our two custom ones
  // eEnable (turn on/off enable)
  // ePMBus  (send PMBus command - ok really just 'send a set of I2C bytes')

  if (curTmp == eTemps) goto do_Temps;
  if (curTmp == eVolts) goto do_Volts;
  if (curTmp == eIdentify) goto do_Identify;
  if (curTmp == eCurrents) goto do_Currents;
  if (curTmp == eStatistics) goto do_Statistics;
  if (curTmp == eEnable) goto do_Enable;
  if (curTmp == ePMBus) goto do_PMBus;
  if (curTmp != ePingPong) goto droppedPacket;
 do_PingPong:
  hsk_header();
  // already have a checksum, we're done
  goto goodPacket;  
  
 do_Statistics:
  hsk_header();
  outputk(PACKET_LEN_K, Statistics_LENGTH);
  fetch(scratch_RXCOUNT, &s9);
  output(PACKET_DATA, s9);
  fetch(scratch_TXCOUNT, &curTmp);
  output(PACKET_DATA+1, curTmp);
  s9 += curTmp;
  fetch(scratch_ERRCOUNT, &curTmp);
  output(PACKET_DATA+2, curTmp);
  s9 += curTmp;
  fetch(scratch_DROPCOUNT, &curTmp);
  output(PACKET_DATA+3, curTmp);
  s9 += curTmp;
  fetch(scratch_SKIPCOUNT, &curTmp);
  output(PACKET_DATA+4, curTmp);
  s9 += curTmp;
  curPtr = (PACKET_DATA+Statistics_LENGTH);
  goto finishPacket;
  
 do_Temps:
  // set up the packet
  hsk_header();
  outputk(PACKET_LEN_K, Temps_LENGTH);
  // now copy the data
  // s9 is the checksum.
  input(TURFIO_BASE+4, &s9);
  output(PACKET_DATA, s9);
  input(TURFIO_BASE+5, &curTmp);
  output(PACKET_DATA+1, curTmp);
  s9 += curTmp;
  curPtr = PACKET_DATA+2;
  s5 = SURF_BASE_TEMP;
  do {
    hsk_copy2();
    s5 += SURF_TEMP_INC;
  } while (s5 != SURF_TEMP_MAX);
  goto finishPacket;

 do_Volts:
  // set up the packet
  hsk_header();
  // add TURFIO volts
  outputk(PACKET_LEN_K, Volts_LENGTH);
  input(TURFIO_BASE, &s9);
  output(PACKET_DATA, s9);
  input(TURFIO_BASE+1, &curTmp);
  output(PACKET_DATA+1, curTmp);
  s9 += curTmp;
  // now loop through SURF volts
  curPtr = PACKET_DATA+2;
  s5 = SURF_BASE_VIN;
  do {
    hsk_copy4();
    s5 += SURF_VOLT_INC;
  } while (s5 != SURF_VIN_MAX);
  goto finishPacket;

 do_Currents:
  hsk_header();
  outputk(PACKET_LEN_K, Currents_LENGTH);
  // add TURFIO current
  input(TURFIO_BASE+2, &s9);
  output(PACKET_DATA, s9);
  input(TURFIO_BASE+3, &curTmp);
  output(PACKET_DATA+1, curTmp);
  s9 += curTmp;
  // now loop through SURFs
  curPtr = PACKET_DATA+2;
  s5 = SURF_BASE_IOUT;
  do {
    hsk_copy2();
    s5 += SURF_CURR_INC;
  } while (s5 != SURF_IOUT_MAX);
  goto finishPacket;

 do_Enable:
  hsk_header();
  input(PACKET_LEN, &curTmp);
  if (curTmp != 0) {
    input(PACKET_DATA, &curTmp);
    input(GC_PORT, &curTmp2);
    curTmp2 &= 0x7F;
    if (curTmp != 0) {
      curTmp2 |= 0x80;
    }
    output(GC_PORT, curTmp2);    
  }
  input(GC_PORT, &curTmp);
  if (curTmp & 0x80) {
    outputk(PACKET_DATA_K, 0x01);
    outputk(PACKET_DATA_K+1, 0xFF);
  } else {
    outputk(PACKET_DATA_K, 0x00);
    outputk(PACKET_DATA_K+1, 0x00);
  }
  outputk(PACKET_LEN_K, Enable_LENGTH);
  // we already handled checksum, just jump past
  goto goodPacket;

 do_PMBus:
  // THE PACKET INTERFACE SHOULD BE STRAIGHTFORWARD
  // IF A WRITE, CHECK IF scratch_PMBus_WPtr is 0
  //    IF YES: WRITE DATA TO BUFFER AND UPDATE WPtr/RPtr, RETURN # BYTES
  //    IF NO: RETURN 0
  // IF A READ, return scratch_PMBus_RPtr BYTES FROM
  //    scratch_PMBus_BASE and zero scratch_PMBus_RPtr

  // flippy flippy
  hsk_header();
  // check if it's a read or write
  input(PACKET_LEN, &curTmp);
  if (curTmp == 0) goto PMBus_Read;

  // write attempt
  // store length, it's always 1
  outputk(PACKET_LEN_K, 1);
  
  // check if we're currently writing
  fetch(scratch_PMBus_WPtr, &curTmp2);
  if (curTmp2 == 0) goto PMBus_Write;

  // we are currently writing, screw off  
  outputk(PACKET_DATA_K, 0x00);
  outputk(PACKET_DATA_K+1, 0x00);
  // checksum's done, skip it
  goto goodPacket;

 PMBus_Write:
  // no, we're not, so we're going to save data
  // set WPtr and clear RPtr
  store(scratch_PMBus_WPtr, curTmp);
  // we know curTmp2 is 0 because of above
  store(scratch_PMBus_RPtr, curTmp2);
  
  // build up the packet (just # of bytes)
  output(PACKET_DATA, curTmp);
  // we can calc our checksum easier, so do it here
  curTmp2 -= curTmp;
  output(PACKET_DATA+1, curTmp2);
  // packet is complete at this point, just need to memcpy.
  // note we use goodPacket not finishPacket
  
  // memcpy curTmp bytes from PACKET_DATA to scratch_PMBus_BASE
  s4 = PACKET_DATA;
  s5 = scratch_PMBus_BASE;
  do {
    input(s4, &curTmp2);
    store(s5, curTmp2);
    s4++;
    s5++;
    } while (--curTmp);
  goto goodPacket;

 PMBus_Read:
  // read
  // is there any data to read
  fetch(scratch_PMBus_RPtr, &curTmp);
  if (curTmp == 0) {
    // no
    outputk(PACKET_LEN_K, 0);
    outputk(PACKET_DATA_K, 0);
    // checksum's done, just jump past
    goto goodPacket;      
  }
  // yes have data
  output(PACKET_LEN, curTmp);
  s4 = scratch_PMBus_BASE;
  curPtr = PACKET_DATA;
  s9 = 0;
  // curPtr ends up at checksum here
  do {
    fetch(s4, &curTmp2);
    s9 += curTmp2;
    output(curPtr, curTmp2);
    s4++;
    curPtr++;
  } while (--curTmp);
  goto finishPacket;

 do_Identify:
  hsk_header();
  outputk(PACKET_LEN_K, Identify_LENGTH);
  // add constant
  s9 = PB_TURFIO_VERSION;
  output(PACKET_DATA, s9);
  // add which SURFs were found
  fetch(scratch_PRESENT, &curTmp);
  s9 += curTmp;
  output(PACKET_DATA+1, curTmp);
  curPtr = PACKET_DATA+2;
  // we don't need a finishPacket jump
  // we're already there
  
 finishPacket:
  s9 ^= 0xFF;
  s9 += 1;
  output(curPtr, s9);
 goodPacket:
  cobsEncode();
  curTmp2 = scratch_RXCOUNT;
  fetchAndIncrement();
  curTmp2 = scratch_TXCOUNT;
 fetchAndIncrement:
  fetch(curTmp2, &curTmp);
  curTmp++;
  store(curTmp2, curTmp);
}

// these are actually jump targets
void skippedPacket(void) __attribute__((noreturn));
void skippedPacket() {
  curTmp2 = scratch_SKIPCOUNT;
  goto fetchAndIncrement;
}

void droppedPacket(void) __attribute__((noreturn));
void droppedPacket() {
  curTmp2 = scratch_DROPCOUNT;
  goto fetchAndIncrement;
}

void errorPacket(void) __attribute__((noreturn));
void errorPacket() {
  curTmp2 = scratch_ERRCOUNT;
  goto fetchAndIncrement;
}

// swappy-swappy
void hsk_header() {
  input(PACKET_SRC, &curTmp);
  output(PACKET_DST, curTmp);
  output(PACKET_SRC, ourID);  
}

// copy bytes from s5 to curPtr saving
// checksum in s9
// gotta love magic recursion
void hsk_copy4() {
  hsk_copy2();
 hsk_copy2:
  hsk_copy1();
 hsk_copy1:
  input(s5, &curTmp);
  output(curPtr, curTmp);
  s9 += curTmp;
  s5++;
  curPtr++;
}

/////////////////////////////
// I2C OPERATION FUNCTIONS //
/////////////////////////////
// These only clobber      //
// curTmp/curTmp2.         //
//                         //
// The delays preserve C   //
// and rx bit returns bit  //
// val in C.               //
/////////////////////////////

// Sigh. Our I2C stuff sucks.
// Let's see how fast we can run this.
// 400 kHz is 2.5 us = 1.25 us clock up/down
// wbclk is 80 MHz = 12.5 ns, so we have 100
// clocks per up/down or 50 instructions per.
// Jump/ret automatically give us 2 instructions.
// let's make it a bit longer at 1/3, which is
// 16 instrs including call/ret
// then call call call gives 48 and including


// I2C_delay_short is 15 instructions:
// this means overall this is 47 instructions.
// this allows overhead stuff to be embedded in
void I2C_delay_hclk() {
  I2C_delay_short();
 I2C_delay_med:
  I2C_delay_short();
  I2C_delay_short();
}

// ok! so we do SUPER-WEIRDNESS here!
// our goal is to provide a 15 clock delay
// WHILE PRESERVING C
// THIS IS FINE EVERYTHING IS FINE
// 1 call
// 2 sla curTmp2
// 3 load curTmp, 0x08
// 4 sla curTmp (0x10)
// 5 jump NC
// 6 sla curTmp (0x20)
// 7 jump NC
// 8 sla curTmp (0x40)
// 9 jump NC
// 10 sla curTmp (0x80)
// 11 jump NC
// 12 sla curTmp
// 13 jump NC
// 14 sra curTmp2
// 15 ret
// EVERYTHING IS AWESOME
#define SHORT_INIT 0x08
void I2C_delay_short() {
  // I SHOULD MAKE THIS INTRINSICS
  psm("sla %1", curTmp2);
  curTmp = 0x08;
  do {
    psm("sla %1", curTmp);
  } while (!C);
  psm("sra %1", curTmp2);
}    

// we assume clock is low
void I2C_Rx_bit() {
  I2C_data_Z();
  I2C_delay_hclk();
  I2C_clk_Z();
  I2C_delay_hclk();
  input(I2C_input_port, curTmp);
  // test will set C here bc I2C_data is a single bit
  psm("test %1, %2", curTmp, I2C_data);
  I2C_clk_Low();
  // C is set if bit is high
}

void I2C_stop() {
  I2C_data_Low();  
  I2C_delay_short();
  I2C_clk_Z();
  I2C_delay_med();
  I2C_data_Z();
  I2C_delay_short();
}

void I2C_start() {
  I2C_data_Z();
  I2C_clk_Z();
  I2C_delay_med();
  I2C_data_Low();
  I2C_delay_short();
  I2C_clk_Low();
}

/////////////////////////////
// I2C INTERNAL FUNCTIONS  //
/////////////////////////////
// These either take or    //
// return sA. Clobber sB.  //
// They don't alter sA.    //
// Also curTmp/curTmp2.    //
/////////////////////////////

// our possible I2C operations
// init: st waddr 0xd4 0x1e 0x07 sr waddr 0xD8 0x01 0x8D sp
// read vin:  st waddr 0x8b sr raddr data data sp
// read vout: st waddr 0x8b sr raddr data data sp
// read iout: st waddr 0x8c sr raddr data data sp
// read temp: st waddr 0x8d sr raddr data data sp
// reset st waddr 0xD8 0x01 0x0D sp
// ok interesting thing is that we can actually just cheeseball
// this
// we need literally 2 operations: write 3 bytes and write 1 read 2

// transmit in sA, uses sB since delays use curTmp
// sB          sA          C
// 0000_0001   HGEFDCBA    X rl sA
// 0000_0001   GEFDCBAH    H sla sB
// 0000_001H   GEFDCBAH    0 output sB, jump NC, rl sA
// 0000_001H   EFDCBAHG    G sla sB
// 0000_01HG   EFDCBAHG    0 output sB, jump NC, rl sA
// 0000_01HG   FDCBAHGE    E sla sB
// 0000_1HGE   FDCBAHGE    0 output sB, jump NC, rl sA
// 0000_1HGE   DCBAHGEF    F sla sB
// 0001_HGEF   DCBAHGEF    0 output sB, jump NC, rl sA
// 0001_HGEF   CBAHGEFD    D sla sB
// 001H_GEFD   CBAHGEFD    0 output sB, jump NC, rl sA
// 001H_GEFD   BAHGEFDC    C sla sB
// 01HG_EFDC   BAHGEFDC    0 output sB, jump NC, rl sA
// 01HG_EFDC   AHGEFDCB    B sla sB
// 1HGE_FDCB   AHGEFDCB    0 output sB, jump NC, rl sA
// 1HGE_FDCB   HGEFDCBA    A sla sB
// HGEF_DCBA   HGEFDCBA    1 output sB, jump NC return
// SO SLEAZY!!
// the outputk period is 4 instructions
// we add
// I2C_delay_hclk() (47)
// I2C_clk_Z() (1)
// I2C_delay_hclk() (47)
// I2C_clk_Low() (1)
// 96 + 4 = 100 (HOLY CRAPNESS)
// because we preserved C all through the I2C delays this is awesome!
void I2C_Tx_byte_and_Rx_ACK() {
  sB = 0x01;
  do {
    psm("rl %1", sA);
    psm("sla %1", sB);
    output( I2C_output_data, sB);
    I2C_delay_hclk();
    I2C_clk_Z();
    I2C_delay_hclk();
    I2C_clk_Low();
  } while (!C);
  // clock is now low, we're at the beginning of the ack bit
  I2C_Rx_bit();
  // we need a long low transition to allow multiple calls
  // to this function. I2C_delay_hclk preserves C so this is
  // OK.
  I2C_delay_hclk();
  // C is set if bit is high
}

// receive a full byte and return in sA
// note that this does NOT handle the 9th
// bit, that's the "do we want more" bit
// and is an OUTPUT
void I2C_Rx_byte() {
  sA = 0x1;
  do {
    I2C_Rx_bit();
    psm("sla %1", sA);
  } while (!C);  
}

//// These are USER functions.

/////////// I2C_test() - tests presence of device
// Input to function:
//    sA: address to test existence of
// Clobbers:
//    sB/curTmp/curTmp2
// Returns:
//    if C is set device exists
void I2C_test() {
  I2C_start();
  I2C_Tx_byte_and_Rx_ACK();
  I2C_stop();
}

// I2C user tx: s4 contains the pointer to the beginning of the
// transaction. we loop BACKWARDS until we hit the beginning.
// we don't do start/stop that's outside us.
// note that if we return C that's an error, we got a NACK.
// otherwise C is never set because we end on a zero.
void I2C_user_tx_process() {
  do {
    fetch(s4, &sA);
    I2C_Tx_byte_and_Rx_ACK();
    if (C) return;
    s4--;
  } while (s4 != I2C_SP_BUFFERSTOP);  
}

// I2C_send3 takes s4/s5/s6 and sends them to the device address (already in I2CBUFFER3)
// I2C_send1 is a label inside this function which the TURFIO initialize uses.
void I2C_send3() {
  store(scratch_I2CBUFFER2, s4);
  s4 = scratch_I2CBUFFER3;
  store(scratch_I2CBUFFER1, s5);
 I2C_send1_prcs:
  store(scratch_I2CBUFFER, s6);
  I2C_start();
  I2C_user_tx_process();
  I2C_stop();
}

void I2C_turfio_initialize(void) __attribute__((noreturn));
void I2C_turfio_initialize() {
  s4 = I2C_ADDR_TURFIO;
  store(scratch_I2CBUFFER1, s4);
  s4 = scratch_I2CBUFFER1;
  // send command code 5, continuously convert voltage and current
  s6 = 0x5;
  goto I2C_send1_prcs;
}

// initialize surf in sA
// clobbers sA, s4, s5, s6
void I2C_surf_initialize() {
  // save addr: we send 4 bytes (including addr) so this is scratch_I2CBUFFER3
  store(scratch_I2CBUFFER3, sA);
  // step 1: send 0xD4, 0x1E, 0x07 - PMON_CONFIG 0x071E to turn on temp/vout sampling.
  s4 = 0xD4;
  s5 = 0x1E;
  s6 = 0x07;
  I2C_send3();
  // step 2: send 0xD8, 0x8D, 0x01 - DEVICE_CONFIG 0x018D to set up GPO2 as output, active high  
  s4 = 0xD8;
  s5 = 0x8D;
  s6 = 0x01;
  I2C_send3();
}

// s4 = device address
// s5 = value to write
// s6 = pointer to where to write first byte (I2C_SP_BUFFERSTOP + (# of bytes to read - 1)
// clobbers s4
// I2C_read is an embedded function inside here, you store the device address in I2CBUFFER1
// and pass s6.
void I2C_read_register() {
  store(scratch_I2CBUFFER1, s4);
  store(scratch_I2CBUFFER, s5);
  // write register
  I2C_start();
  s4 = scratch_I2CBUFFER1;
  I2C_user_tx_process();
  // restart
 I2C_read:
  I2C_start();
  fetch(scratch_I2CBUFFER1, sA);
  // this is a write
  sA |= 0x1;
  I2C_Tx_byte_and_Rx_ACK();
  // now we need to read bytes
  do {
    // read byte
    I2C_Rx_byte();
    // we've now done
    // __--__--__--__--__--__--__--__--_
    //  D7  D6  D5  D4  D3  D2  D1  D0 
    // at the end of I2C_Rx_byte, clock is low
    // but only immediately so
    store(s6, sA);
    // are we at the end? we want to set C if so
    // to output data.
    psm("compare %1, %2", s6, scratch_I2CBUFFER1);
    psm("sla %1", curTmp);
    output( I2C_output_data, curTmp);    
    // now wait the half
    I2C_delay_hclk();
    // raise clock
    I2C_clk_Z();
    // wait the other half
    I2C_delay_hclk();
    // and clock low
    I2C_clk_Low();
    // decrement pointer
    s6--;
  } while (s6 != I2C_SP_BUFFERSTOP);
  // make pretty
  I2C_delay_hclk();
  // and stop
  I2C_stop();
}

// COBS ENCODING JUNK
// this is SURPRISINGLY cheap but that's because we only
// work with small packets. It wouldn't be much harder
// with large packets but there's no point to consider
// that here since we have no place to store it.

// we bracket these defines in this group of code
// I should do this more often
#define bufPointer s5
#define endPointer s6
#define nextZero s7

/* returns pointer to next zero (or past end of packet) */
/* the search STARTS at bufPointer and continues up TO  */
/* endPointer. nextZero is the pointer TO the found     */
/* zero (or end of packet which is an assumed zero)     */
void cobsFindZero(void) __attribute__((noreturn));
void cobsFindZero() {
  nextZero = bufPointer;
  do {
    if (nextZero == endPointer) return;
    input(nextZero, &curTmp);
    if (curTmp == 0) return;
    nextZero++;
  } while(1);  
}

/* fixes up a zero found inside a COBS packet */
/* this is called when bufPointer is already  */
/* pointing to the next byte                  */
void cobsFixZero() {
  // find the next zero
  cobsFindZero();
  // turn it into an offset from the next byte
  nextZero -= bufPointer;
  // turn it into an offset from the CURRENT byte
  nextZero++;
  // curTmp is what's output
  curTmp = nextZero;
}

/* encodes and outputs a SMALL packet using COBS */
/* this ONLY WORKS because we will NEVER need a second overhead byte */
void cobsEncode() {
  // start at the beginning
  bufPointer = PACKET_BASE;
  // calculate end pointer (1 after last byte - where the null terminator would go)
  input(PACKET_LEN,&endPointer);
  endPointer += (PACKET_BASE+5);
  // find the position of the first zero
  cobsFindZero();
  // change it to offset from the overhead byte (which is effectively PACKET_BASE-1)
  // note this is the same as what happens in cobsFixZero (subtract pointer to
  // next byte, add 1)
  nextZero -= (PACKET_BASE-1);
  // output the overhead byte
  output(UART_TX, nextZero);
  // now transmit the rest of the packet
  do {
    // fetch the byte
    input(bufPointer, &curTmp);
    // increment: bufPointer is now the NEXT byte
    bufPointer++;
    // is it zero? if so, replace it with an offset
    if (curTmp == 0) cobsFixZero();
    // output the byte or the replaced offset
    output(UART_TX, curTmp);    
  } while (bufPointer < endPointer);
  // and output the null terminator
  outputk(UART_TX, 0x00);
}

#undef bufPointer
#undef endPointer
#undef nextZero
