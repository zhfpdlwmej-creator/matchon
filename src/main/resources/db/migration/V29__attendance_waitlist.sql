-- 예비(대기) 인원: 선착순 마감 후 신청자는 WAITLIST 로 등록, waitlist_at 순으로 자동 승급
ALTER TABLE attendance ADD COLUMN waitlist_at TIMESTAMP;
