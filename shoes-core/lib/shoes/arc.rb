# frozen_string_literal: true

class Shoes
  class Arc < Common::ArtElement
    include Math
    # angle is the gradient angle used across all art elements
    # angle1/2 are the angles of the arc itself!
    style_with :angle1, :angle2, :art_styles, :center, :common_styles, :dimensions, :radius, :wedge
    STYLES = { wedge: false, fill: Shoes::COLORS[:black] }.freeze

    def create_dimensions(left, top, width, height, angle1, angle2)
      @style[:angle1] = angle1 || @style[:angle1] || 0
      @style[:angle2] = angle2 || @style[:angle2] || 0

      left   ||= @style[:left] || 0
      top    ||= @style[:top] || 0
      width  ||= @style[:width] || 0
      height ||= @style[:height] || 0

      @dimensions = Dimensions.new parent, left, top, width, height, @style
    end

    def wedge?
      wedge
    end

    def radius_x
      @radius_x ||= width.to_f / 2
    end

    def radius_y
      @radius_y ||= height.to_f / 2
    end

    def middle_x
      @middle_x ||= left + radius_x
    end

    def middle_y
      @middle_y ||= top + radius_y
    end

    def oval_axis_fraction(axis, input, difference = 0)
      # x_side = (((x - middle_x)**2).to_f / radius_x**2)
      (((input - send("middle_#{axis}")) ** 2).to_f / ((send("radius_#{axis}") - difference) ** 2))
    end

    def inner_oval_axis_fraction(axis, input)
      oval_axis_fraction(axis, input, inner_oval_difference)
    end

    def inside_oval?(x, y)
      (oval_axis_fraction(:x, x) + oval_axis_fraction(:y, y)) <= 1
    end

    def inside_inner_oval?(x, y)
      x_side = inner_oval_axis_fraction(:x, x)
      y_side = inner_oval_axis_fraction(:y, y)
      x_side + y_side <= 1
    end

    def normalize_angle(input_angle)
      # This fixes angles > 6.283185 and < 0
      input_angle % (Math::PI * 2)
    end

    def adjust_angle(input_angle)
      # Must pad angle, since angles in standard formulas start at different location than in shoes
      adjusted_angle = input_angle + 1.5708

      # Must make angle 0..6.28318
      adjusted_angle = normalize_angle(adjusted_angle)
    end

    def y_adjust_negative?(input_angle)
      ((input_angle >= 0) && (input_angle <= 1.5708)) || ((input_angle >= 4.71239) && (input_angle <= 6.28319))
    end

    def x_adjust_positive?(input_angle)
      (input_angle >= 0) &&  (input_angle <= 3.14159)
    end

    def y_result_adjustment(input_angle, y_result)
      if y_adjust_negative?(input_angle)
        middle_y - y_result
      else
        middle_y + y_result
      end
    end

    def x_result_adjustment(input_angle, x_result)
      if x_adjust_positive?(input_angle)
        middle_x + x_result
      else
        middle_x - x_result
      end
    end

    def generate_coordinates(input_angle, x_result, y_result)
      x_result = x_result_adjustment(input_angle, x_result).round(3)
      y_result = y_result_adjustment(input_angle, y_result).round(3)

      {
        x_value: x_result,
        y_value: y_result
      }
    end

    def angle_base_coords(given_angle)
      # https://math.stackexchange.com/questions/22064/calculating-a-point-that-lies-on-an-ellipse-given-an-angle
      # The above link was used in creating this method...but the implementation varies due to nature of shoes
      modded_angle = adjust_angle(given_angle)
      top_of_equation = (radius_x * radius_y)

      x_result = top_of_equation / (((radius_y**2) + ((radius_x**2) / (tan(modded_angle)**2)))**0.5)
      y_result = top_of_equation / (((radius_x**2) + ((radius_y**2) * (tan(modded_angle)**2)))**0.5)

      generate_coordinates(modded_angle, x_result, y_result)
    end

    def angle1_coordinates
      @angle1_coordinates ||= angle_base_coords(angle1)
    end

    def angle2_coordinates
      @angle2_coordinates ||= angle_base_coords(angle2)
    end

    def angle1_x
      angle1_coordinates[:x_value]
    end

    def angle1_y
      angle1_coordinates[:y_value]
    end

    def angle2_x
      angle2_coordinates[:x_value]
    end

    def angle2_y
      angle2_coordinates[:y_value]
    end

    def slope_of_angles
      # slope = (y2 - y1) / (x2 - x1)
      (angle2_y - angle1_y) / (angle2_x - angle1_x)
    end

    def b_value_for_line
      # SINCE y = mx + b
      # THEN  b = y - mx
      mx_value = (angle1_x * slope_of_angles)

      if mx_value == Float::INFINITY
        angle1_y
      else
        angle1_y - mx_value
      end
    end

    def vertical_check(x_input)
      # The above/below are
      if angle1_x == x_input
        :on
      elsif angle1_x < x_input
        :above
      else
        :below
      end
    end

    def normal_above_below_check(mx_value, y_input)
      right_side_of_equation = mx_value + b_value_for_line

      if right_side_of_equation == y_input
        # If input y is same...input is on the line
        :on
      elsif right_side_of_equation > y_input
        # If input y is more, point is above the line
        :above
      else
        # If input y is less, point is below the line
        :below
      end
    end

    def above_below_on(x_input, y_input)
      mx_value = (x_input * slope_of_angles)

      if mx_value.abs > 1_000_000.00
        # If line is straight up and down..compare with x value to an x coordinate
        vertical_check(x_input)
      else
        # If standard slope...find what the y value would be given the input x
        normal_above_below_check(mx_value, y_input)
      end
    end

    def angle1_smaller_check(x,y)
      above_below_on(x, y) == :below && angle1_x > angle2_x
    end

    def angle2_smaller_check(x,y)
      above_below_on(x, y) == :above && angle1_x < angle2_x
    end

    def on_shaded_part?(x, y)
      angle1_smaller_check(x,y) || angle2_smaller_check(x,y)
    end

    def standard_arc_bounds_check(x,y)
      inside_oval?(x, y) && on_shaded_part?(x, y)
    end

    def inner_oval_difference
      @inner_oval_difference ||= calculate_inner_oval_difference
    end

    def calculate_inner_oval_difference
      difference = style[:strokewidth].to_i * 2

      difference = 4 if difference < 4

      difference.to_f / 2
    end

    def in_bounds?(x, y)
      bounds_check = standard_arc_bounds_check(x,y)

      if bounds_check && !style[:fill]

        bounds_check = !inside_inner_oval?(x, y)
      end

      bounds_check
    end
  end
end
