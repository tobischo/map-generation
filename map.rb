#!/usr/bin/env ruby

require 'RMagick'

#thanks to http://devmag.org.za/2009/04/25/perlin-noise/ for the algorithm

def GenerateWhiteNoise(width, height, seed)

	r = Random.new(seed)
	noise = Array.new(width) { Array.new(height)}

	i = 0
	while i < width do
		j = 0
		while j < height do
			noise[i][j] = (r.rand(2000)-1000)/1000.0
			j=j+1
		end
		i=i+1
	end
	return noise
end

def GenerateSmoothNoise(baseNoise, octave)
	width = baseNoise.size
	height = baseNoise[0].size

	smoothNoise = Array.new(width) { Array.new(height)}

	samplePeriod = (1 << octave).to_i
	sampleFrequency = 1.0/samplePeriod

	i = 0
	while i < width do
		sample_i0 = (i / samplePeriod) * samplePeriod
		sample_i1 = (sample_i0 + samplePeriod) % width
		horizontal_blend = Float((i - sample_i0) * sampleFrequency)

		j = 0
		while j < height do
			sample_j0 = (j/samplePeriod) * samplePeriod
			sample_j1 = (sample_j0 + samplePeriod) % height
			vertical_blend = Float((j - sample_j0) * sampleFrequency)

			top = interpolate(baseNoise[sample_i0][sample_j0], baseNoise[sample_i1][sample_j0], horizontal_blend)

			bottom = interpolate(baseNoise[sample_i0][sample_j1],baseNoise[sample_i1][sample_j1], horizontal_blend)

			smoothNoise[i][j] = interpolate(top, bottom, vertical_blend)
			j=j+1
		end
		i=i+1
	end
	return smoothNoise
end

def interpolate(x0, x1, alpha)
	return Float(x0) * (1 - Float(alpha)) + Float(alpha) * Float(x1)
end

def GeneratePerlinNoise(baseNoise, octaveCount)
	width = baseNoise.size
	height = baseNoise[0].size

	smoothNoise = Array.new(octaveCount)

	persistence = 0.5

	i = 0
	while i < octaveCount do
		smoothNoise[i] = GenerateSmoothNoise(baseNoise,i)
		i=i+1
	end

	perlinNoise = Array.new(width) { Array.new(height) {0}}
	amplitude = 1.0
	totalAmplitude = 0.0

	octave = octaveCount - 1
	while octave >= 0 do
		amplitude = amplitude * persistence
		totalAmplitude = totalAmplitude + amplitude
		
		i = 0
		while i < width do
			j = 0
			while j < height do
				perlinNoise[i][j] += smoothNoise[octave][i][j] * amplitude
				j=j+1
			end
			i=i+1
		end

		octave=octave-1
	end

	i = 0
	while i < width do
		j=0
		while j < height do
			perlinNoise[i][j] = perlinNoise[i][j] / totalAmplitude
			j=j+1
		end
		i=i+1
	end

	return perlinNoise

end

def GenerateImage(width, height, seed, octave)

	watergradient = Magick::Image.new(100,100, Magick::GradientFill.new(0,0,100,0, "#6db3f2", "#1D23D3"))
	beachgradient = Magick::Image.new(100,100, Magick::GradientFill.new(0,0,100,0, "#DAF791", "#F9EC72"))
	forestgradient = Magick::Image.new(100,100, Magick::GradientFill.new(0,0,100,0, "#F9EC72", "#208900"))
	mountaingradient = Magick::Image.new(100,100, Magick::GradientFill.new(0,0,100,0, "#208900", "#e48625"))
	mountaintopgradient = Magick::Image.new(100,100, Magick::GradientFill.new(0,0,100,0, "#e48625", "#FFFFFF"))

	canvas = Magick::Image.new(width, height)
	gc = Magick::Draw.new
	bw = Magick::Image.new(width, height)	
	bwd = Magick::Draw.new

	map = Array.new(width) { Array.new(height)}
	map = GeneratePerlinNoise(GenerateWhiteNoise(width,height,seed),octave)

	i = 0
	while i < width do
		j = 0
		while j < height do
			if map[i][j] >= 0.05 && map[i][j] < 0.3 then
				gc.fill(forestgradient.pixel_color(1,(100*(map[i][j]-0.05)/0.25).to_i).to_color)
			elsif map[i][j] >= 0 && map[i][j] < 0.05 then
				gc.fill(beachgradient.pixel_color(1,(100*map[i][j]/0.05).to_i).to_color)
			elsif map[i][j] >= 0.3 && map[i][j] < 0.75 then
				gc.fill(mountaingradient.pixel_color(1,(100*(map[i][j]-0.3)/0.45).to_i).to_color)
			elsif map[i][j] >= 0.75 then
				gc.fill(mountaintopgradient.pixel_color(1,(100*(map[i][j]-0.75)/0.25).to_i).to_color)
			else
				gc.fill(watergradient.pixel_color(1,(100*map[i][j]*-1).to_i).to_color)
			end
			
			gc.point(i,j)
			
			bwd.fill('rgb('+String(127+127*map[i][j])+','+String(127+127*map[i][j])+','+String(127+127*map[i][j])+')')
			bwd.point(i,j)

			j=j+1
		end
		i=i+1
	end

	gc.draw(canvas)
	bwd.draw(bw)
	bw.write("map_bw.png")
	#bw.display
	#canvas.display
	canvas.write("map.png")
end

GenerateImage(1000,1000,12345,9)
