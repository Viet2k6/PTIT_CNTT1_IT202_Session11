USE social_network_pro;

DELIMITER //

CREATE PROCEDURE get100()
BEGIN
    SELECT * FROM notifications LIMIT 100;
END //

DELIMITER ;
CALL get100();
DROP PROCEDURE IF EXISTS get100;


-- Procedure tính tổng 2 số
DELIMITER //

CREATE PROCEDURE sumAB(
    IN a INT, 
    IN b INT, 
    OUT sum INT
)
BEGIN
    SET sum = a + b;
END //

DELIMITER ;
CALL sumAB(2, 4, @result);
SELECT @result;


-- Lấy danh sách người dùng theo phân trang
DELIMITER //

CREATE PROCEDURE getUserListByLimit(
    IN page_number INT, 
    IN page_size INT
)
BEGIN
    DECLARE os INT;
    SET os = (page_number - 1) * page_size;

    SELECT full_name
    FROM users
    ORDER BY user_id
    LIMIT page_size OFFSET os;
END //

DELIMITER ;
CALL getUserListByLimit(2, 5);
DROP PROCEDURE IF EXISTS getUserListByLimit;

-- Thêm mới 1 người dùng
DELIMITER //
CREATE PROCEDURE addNewUser(
    IN user_id INT,
    IN username VARCHAR(50),
    IN full_name VARCHAR(100),
    IN gender ENUM('Nam','Nữ'),
    IN email VARCHAR(100),
    IN password VARCHAR(100),
    IN birthdate DATE,
    IN hometown VARCHAR(100),
    IN created_at DATETIME
)
BEGIN
    INSERT INTO users (
        user_id, username, full_name, gender,
        email, password, birthdate, hometown, created_at
    )
    VALUES (
        user_id, username, full_name, gender,
        email, password, birthdate, hometown, created_at
    );
END //

DELIMITER ;
CALL addNewUser(
    111, 'an', 'Lê Văn An', 'Nam',
    'an@gmail.com', '1234567',
    '2000-10-20', 'Đà Nẵng', NOW()
);


-- Chỉnh sửa người dùng theo ID
DELIMITER //

CREATE PROCEDURE updateUser(
    IN u_user_id INT,
    IN u_username VARCHAR(50),
    IN u_full_name VARCHAR(100),
    IN u_gender ENUM('Nam','Nữ'),
    IN u_email VARCHAR(100),
    IN u_password VARCHAR(100),
    IN u_birthdate DATE,
    IN u_hometown VARCHAR(100)
)
BEGIN
    UPDATE users
    SET 
        username = u_username,
        full_name = u_full_name,
        gender = u_gender,
        email = u_email,
        password = u_password,
        birthdate = u_birthdate,
        hometown = u_hometown
    WHERE user_id = u_user_id;
END //

DELIMITER ;
CALL updateUser(
    1, 'hieu', 'Lê Văn Hiếu', 'Nam',
    'hieu@gmail.com', '1234567',
    '2000-10-20', 'Đà Nẵng'
);


-- Xóa người dùng theo ID

DELIMITER //

CREATE PROCEDURE deleteUser(
    IN user_id_in INT
)
BEGIN
    DELETE FROM users
    WHERE user_id = user_id_in;
END //

DELIMITER ;
CALL deleteUser(111);


-- Bài 1: Lấy danh sách bài viết theo user
DELIMITER //

CREATE PROCEDURE getUserPostById(
    IN p_user_id INT
)
BEGIN
    SELECT post_id, content, created_at
    FROM posts
    WHERE user_id = p_user_id;
END //

DELIMITER ;
CALL getUserPostById(2);
DROP PROCEDURE IF EXISTS getUserPostById;


-- Bài 2: Đếm tổng số like của 1 bài viết
DELIMITER //

CREATE PROCEDURE totalLikes(
    IN p_post_id INT,
    OUT total_likes INT
)
BEGIN
    SELECT COUNT(*) INTO total_likes
    FROM likes
    WHERE post_id = p_post_id;
END //

DELIMITER ;
CALL totalLikes(101, @total_likes);
SELECT @total_likes;
DROP PROCEDURE IF EXISTS totalLikes;

-- Bài 3: Tính điểm thưởng (INOUT)
DELIMITER //

CREATE PROCEDURE CalculateBonusPoints(
    IN p_user_id INT,
    INOUT p_bonus_points INT
)
BEGIN
    DECLARE v_post_count INT DEFAULT 0;

    SELECT COUNT(*) INTO v_post_count
    FROM posts
    WHERE user_id = p_user_id;

    IF v_post_count >= 20 THEN
        SET p_bonus_points = p_bonus_points + 100;
    ELSEIF v_post_count >= 10 THEN
        SET p_bonus_points = p_bonus_points + 50;
    END IF;
END //

DELIMITER ;
SET @current_bonus = 100;
CALL CalculateBonusPoints(1, @current_bonus);
SELECT @current_bonus;
DROP PROCEDURE IF EXISTS CalculateBonusPoints;

-- Bài 4: Thêm bài viết có kiểm tra dữ liệu
DELIMITER //

CREATE PROCEDURE CreatePostWithValidation(
    IN p_user_id INT,
    IN p_content TEXT,
    OUT result_message VARCHAR(255)
)
BEGIN
    IF CHAR_LENGTH(p_content) < 5 THEN
        SET result_message = 'Nội dung quá ngắn (tối thiểu 5 ký tự)';
    ELSE
        INSERT INTO posts (user_id, content, created_at)
        VALUES (p_user_id, p_content, NOW());

        SET result_message = 'Thêm bài viết thành công';
    END IF;
END //

DELIMITER ;
CALL CreatePostWithValidation(1, 'Học SQL thật là thú vị!', @msg1);
SELECT @msg1;

CALL CreatePostWithValidation(1, 'Hi', @msg2);
SELECT @msg2;

DROP PROCEDURE IF EXISTS CreatePostWithValidation;

-- Bài 5: Tính điểm hoạt động người dùng
DELIMITER //

CREATE PROCEDURE CalculateUserActivityScore(
    IN p_user_id INT,
    OUT activity_score INT,
    OUT activity_level VARCHAR(50)
)
BEGIN
    DECLARE v_post_count INT DEFAULT 0;
    DECLARE v_comment_count INT DEFAULT 0;
    DECLARE v_like_received_count INT DEFAULT 0;

    SELECT COUNT(*) INTO v_post_count
    FROM posts
    WHERE user_id = p_user_id;

    SELECT COUNT(*) INTO v_comment_count
    FROM comments
    WHERE user_id = p_user_id;

    SELECT COUNT(l.like_id) INTO v_like_received_count
    FROM likes l
    JOIN posts p ON l.post_id = p.post_id
    WHERE p.user_id = p_user_id;

    SET activity_score =
        (v_post_count * 10)
      + (v_comment_count * 5)
      + (v_like_received_count * 3);

    SET activity_level = CASE
        WHEN activity_score > 500 THEN 'Rất tích cực'
        WHEN activity_score BETWEEN 200 AND 500 THEN 'Tích cực'
        ELSE 'Bình thường'
    END;
END //

DELIMITER ;
CALL CalculateUserActivityScore(1, @score, @level);

SELECT full_name, @score AS score, @level AS level
FROM users
WHERE user_id = 1;

DROP PROCEDURE IF EXISTS CalculateUserActivityScore;
