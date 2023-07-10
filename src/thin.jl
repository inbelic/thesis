using Images, ImageView, ImageBinarization

# Here we implement a fast parallel thinning algorithm to create a skeleton
# of our vascular network

# B is a binary
function thin(bin_img)
    while true
        M, done = apply_thin_function(thin_se, bin_img)
        if done
            break
        end
        bin_img = bin_img && (~M)
        M, done = apply_thin_function(thin_nw, bin_img)
        if done
            break
        end
        bin_img = bin_img && (~M)
    end
    return bin_img
end

function thin_se(ps)
    # Evaluate the various conditions
    a = check_sum(ps)
    b = check_pattern(ps)
    c = (ps[2] * ps[4] * ps[6]) == 0
    d = (ps[4] * ps[6] * ps[8]) == 0
    ps[1] && (a && b && c && d)
end

function thin_nw(ps)
    # Evaluate the various conditions
    a = check_sum(ps)
    b = check_pattern(ps)
    c = ps[2] * ps[4] * ps[8] == 0
    d = ps[2] * ps[6] * ps[8] == 0
    ps[1] && (a && b && c && d)
end

function check_sum(ps)
    s = sum(ps) 
    2 <= s && s <= 6
end

function check_pattern(ps)
    sum([ps[i-1] == 0 && ps[i] == 1 for i=3:9]) == 1
end

function encode_window(window)
    # Encode the (peculiar) pixel positions
    p1 = window[2, 2]
    p2 = window[1, 2]
    p3 = window[1, 3]
    p4 = window[2, 3]
    p5 = window[3, 3]
    p6 = window[3, 2]
    p7 = window[3, 1]
    p8 = window[2, 1]
    p9 = window[1, 1]
    return [p1, p2, p3, p4, p5, p6, p7, p8, p9]
end

function apply_thin_function(thin_func, bin_img)
    nrows, ncols = size(bin_img)
    padded = zeros(nrows + 2, ncols + 2) .== 1
    padded[2:nrows+1, 2:ncols+1] = bin_img
    result = zeros(nrows, ncols) .== 1

    # Can be computed in parallel
    for i in 2:nrows+1
        for j in 2:ncols+1
            window = @view padded[i-1:i+1, j-1:j+1]
            ps = encode_window(window)
            result[i-1, j-1] = thin_func(ps)
        end
    end
    return result
end

function test()
    alg = Otsu()
    bin_img = binarize(load("demo2.png"), alg) .> 0.5
    thinned = thin(bin_img)
end

function main()
    alg = Otsu()
    bin_img = binarize(load("demo.png"), alg) .> 0.5
    thinned = thin(bin_img)
end
