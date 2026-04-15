from time import now

struct TaskEstimator:
    # ค่าเฉลี่ยจากสถิติ (Know-how: 100 tokens ใช้เวลาประมาณ 2 วินาทีบนเครื่องเรา)
    alias SEC_PER_100_TOKENS = 2.0 
    alias SDR_BASE_LATENCY = 1.5

    fn estimate_ollama(self, prompt_len: Int) -> Float64:
        # คำนวณคร่าวๆ: ยิ่ง Prompt ยาว ยิ่งใช้เวลาประเมินนานขึ้น
        let estimated = (prompt_len / 100.0) * self.SEC_PER_100_TOKENS
        return estimated + 0.5 # เผื่อเวลา Network Latency ไว้หน่อย

    fn estimate_sdr(self, sample_rate: Int) -> Float64:
        return self.SDR_BASE_LATENCY + (sample_rate / 1000000.0)

# วิธีนำไปใช้
fn main():
    let estimator = TaskEstimator()
    let wait_time = estimator.estimate_ollama(500) # สมมติส่งมา 500 ตัวอักษร
    print("Estimated wait time: ", wait_time, " seconds")