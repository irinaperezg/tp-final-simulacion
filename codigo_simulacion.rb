# frozen_string_literal: true

require 'pty'

HV = 99999999999999999999999999
TF = 1800000

# Variables de control
M = 2 #Mesas de 4
N = 14 #Mesas de 2
P = false
class Simulador
  def simular
    condiciones_iniciales
    while @t < TF
      comienzo
    end
    resultados
  end

  def comienzo
    @i = menor_tps(@tps2)
    @j = menor_tps(@tps4)
    #@k = menor_tps(@tps6) --> En teoria no vamos a usar
    proximo_tps
  end

  def condiciones_iniciales

    @ia = 0
    @ta = 0
    @tps2 = Array.new(M, HV)
    @tps4 = Array.new(N, HV)
    @ito2 = Array.new(M, 0)
    @ito4 = Array.new(N, 0)
    #@tps6 = Array.new(N, HV)
    @tpll = 0
    @cp = 0 # Cantidad de personas que contiene un grupo

    # Variables de estado (COLAS)
    @ns2 = 0
    @ns4 = 0
    @ns6 = 0

    # Resultados --> TODO
    @pta2 = 0.0 #Porcentaje de arrepentidos de grupos de 2.
    @pta4 = 0.0 #Porcentaje de arrepentidos de grupos de 4.
    @pta6 = 0.0 #Porcentaje de arrepentidos de grupos de 6.
    @pca = 0.0 #Promedio de comensales atendidos por jornada.

    # Tiempo de inicio y final de simulación
    @t = 0

    # Tiempos de atención?? no se, checkear
    @te2 = 0.0
    @te4 = 0.0
    @te6 = 0.0

    #Contadores
    @pa2 = 0 #Grupos de 2 arrepentidos.
    @pa4 = 0 #Grupos de 4 arrepentidos.
    @pa6 = 0 #Grupos de 6 arrepentidos.
    @a2 = false #Flag de arrepentimiento de grupo de 2.
    @a4 = false #Flag de arrepentimiento de grupo de 4.
    @a6 = false #Flag de arrepentimiento de grupo de 6.
    @scp = 0 #Personas totales atendidas. TODO HAY Q CONTAR CADA VEZ Q LLEGA ALGUIEN 
    @nt2 = 0 #Mesas totales atendidas de 2.
    @nt4 = 0 #Mesas totales atendidas de 4.
    @nt6 = 0 #Mesas totales atendidas de 6.
    @sto2 = 0 #Sumatoria de Tiempo Ocioso de mesas de 2.
    @sto4 = 0 #Sumatoria de Tiempo Ocioso de mesas de 4.


    @cr2 = 0 #cantidad de rechazados de  grupo de 2 en mesas de 4
    #@cra2 = 0 #cantidad de rechazados de  grupo de 2 en mesas de 4 arrepentidos
    @c24 = 0 #cantidad aceptada de grupo de 2 en mesas de 4


  end

  def menor_tps(vector)
    menor_valor = vector.min
    indice_menor_valor = vector.index(menor_valor)
    indice_menor_valor
  end

  def tps_hv(vector)
    mayor_valor = vector.max
    indice_mayor_valor = vector.index(mayor_valor)
    indice_mayor_valor
  end

# Si no hacemos tps 6 ya estaría, sino hay q actualizarla
  def proximo_tps
    if @tps2[@i] <= @tps4[@j]
      llegada_o_salida2(@tps2[@i])
    else
      llegada_o_salida4(@tps4[@j])
    end
  end

  def llegada_o_salida2(valor)
    if valor < @tpll
      atender_salida2
    else
      atender_llegada
    end
  end

  def llegada_o_salida4(valor)
    if valor < @tpll
      atender_salida4
    else
      atender_llegada
    end
  end


 # def llegada_o_salida6(valor)
 #   if valor < @tpll
 #     atender_salida6
 #   else
 #     atender_llegada
 #   end
 # end

  def atender_salida2
    @t = @tps2[@i]
    @ns2 -= 1
    if @ns2 < M
      @te2 = resolver_estadia_2
      @tps2[@i] = @t + @te2
    else
      @ito2[@i] = @t
      @tps2[@i] = HV
    end

  end

  def resolver_estadia_2
    r = rand(0.0..1.0)
    x = 61 * r + 58
    x
  end

  def atender_salida4
    @t = @tps4[@j]
    @ns4 -= 1
    if @ns4 <= N
      @te4 = resolver_estadia_4
      @tps4[@j] = @t + @te4
    elsif @ns2 >= M && P == true
      @ns2 -= 1
      @ns4 += 1
      @c24 += 1
      @te2 = resolver_estadia_2
      @tps4[@j] = @t + @te2
    else
      @ito4[@j] = @t
      @tps4[@j] = HV
    end

  end

  def resolver_estadia_4
    r = rand(0.0..1.0)
    x = 66 * r + 88
    x
  end

  # TODO o no
  def atender_salida6
  end

  def resolver_estadia_6
    r = rand(0.0..1.0)
    x = 77 * r + 83
    x
  end

  def atender_llegada
    @t = @tpll
    @ia = resolver_ia
    @tpll = @t + @ia

    # hay q cambiar esto para  dejar de  dejar a gente anotarse, como sabemos la hora del dia?
    if @t % 180 >= 140 && (@ns2 + @ns4 + @ns6) > (5 + N + M)

    else
      cant_personas
    end
  end

  def resolver_ia
    r = rand(0.19149..0.99999935)
    x = (Math.log(1 - r) / Math.log(0.80851)) - 1
    x
  end

  def cant_personas
    r = rand(0.0..1.0)
    if r <= 0.15
      @cp = 1
      llegada_2p
    elsif r <= 0.45
      @cp = 2
      llegada_2p
    elsif r <= 0.65
      @cp = 3
      llegada_4p
    elsif r <= 0.90
      @cp = 4
      llegada_4p
    elsif r <= 0.95
      @cp = 5
      llegada_6p
    else
      @cp = 6
      llegada_6p
    end
  end

  def llegada_2p
    if @ns2 <= M
      @i = tps_hv(@tps2)
      @te2 = resolver_estadia_2
      @tps2[@i] = @t + @te2
      @sto2 += (@t - @ito2[@i])
      final_llegada_2
    elsif @ns4 <= N
      mesa_2_en_mesa_4
    else
      arrepentimiento_2
    end
  end

  def arrepentimiento_2
    r2 = rand(0.0..1.0)
    if r2 > 0.2
      final_llegada_2
    else
      @pa2 += 1

    end
  end

  def mesa_2_en_mesa_4
    if P #flag activado
      @c24 += 1
      @j = tps_hv(@tps4)
      @te2 = resolver_estadia_2
      @tps4[@j] = @t + @te2
      @sto4 += (@t - @ito4[@i])
      final_llegada_4
    else #flag desacvtivado
      @cr2 += 1
      arrepentimiento_2

    end
  end

  def final_llegada_2
    @nt2 += 1
    @ns2 += 1
    @scp += @cp

  end

  def llegada_4p
    if @ns4 <= N
      @j = tps_hv(@tps4)
      @sto4 += (@t - @ito4[@j])
      @te4 = resolver_estadia_4
      @tps4[@j] = @t + @te4
      final_llegada_4
    else
      arrepentimiento_4
    end
  end

  def arrepentimiento_4
    if (@ns4 - N) <= 2
      r = rand(0.0..1.0)
      @a4 = r <= 0.25
    else
      r = rand(0.0..1.0)
      @a4 = r <= 0.7
    end
    if @a4 # Se arrepiente
      @pa4 += 1

    else
      final_llegada_4
    end
  end

  def final_llegada_4
    @nt4 += 1
    @ns4 += 1
    @scp += @cp

  end

  def llegada_6p
    if @ns6 == 0
      @nt6 += 1
      @scp += @cp
      if @ns4 < N && @ns2 < M
        @ns2 += 1
        @ns4 += 1
        @i = tps_hv(@tps2)
        @j = tps_hv(@tps4)
        @sto2 += (@t - @ito2[@i])
        @sto4 += (@t - @ito4[@j])
        @te6 = resolver_estadia_6
        @tps2[@i] = @t + @te6
        @tps4[@j] = @t + @te6
      else
        @ns6 += 1

      end
    else
      arrepentimiento_6
    end
  end

  def arrepentimiento_6
    if (@ns6 - 1) <= 2
      r = rand(0.0..1.0)
      @a6 = r <= 0.55
    else
      r = rand(0.0..1.0)
      @a6 = r <= 0.85
    end
    if @a6 # Se arrepiente
      @pa6 += 1

    else
      @nt6 += 1
      @ns6 += 1
      @scp += @cp

    end
  end

  def proximo_o_final
    if @t >= TF
      resultados
    else
      comienzo
    end
  end

  def resultados
    calculo_resultados
    impresion_resultados
  end

  #ACTUALIZAR
  def calculo_resultados

    #Porcentajes de arrepentidos
    @pta2 = (@pa2.to_f / (@nt2 + @pa2)) * 100
    @pta4 = (@pa4.to_f / (@nt4 + @pa4)) * 100
    @pta6 = (@pa6.to_f / (@nt6 + @pa6)) * 100

    #promedio de comensales atendidos por jornada.
    @pca = (@scp*180)/@t

    #Porcentaje de Tiempo Ocioso de Mesas
    #@pto2 = (@sto2.to_f /@t)*100
    #@pto4 = (@sto4.to_f /@t)*100

    #for i in 0..(M-1)
    #  @pto2[i] = (@sto2[i].to_f /@t)*100
    #end

    #for j in 0..(N-1)
    #  @pto4[j] = (@sto4[j].to_f /@t)*100
    #end  
    #ESTO ES anterior
    @pr24 = (@cr2.to_f / (@nt4 + @nt2 + @nt6 + @cr2)) * 100
    @ps24 = (@c24.to_f / (@nt4 + @nt2 + @nt6 + @c24)) * 100
  end

  def impresion_resultados
    puts ''
    puts 'Variables de control:'
    puts ''
    puts 'N: ' + N.to_s
    puts 'M: ' + M.to_s
    puts 'P: ' + P.to_s
    puts ''
    puts 'Resultados: '
    puts ''
    puts 'PTA2: ' + format('%.2f', @pta2.to_s) + ' %'
    puts 'PTA4: ' + format('%.2f', @pta4.to_s) + ' %'
    puts 'PTA6: ' + format('%.2f', @pta6.to_s) + ' %'
    #puts 'PTO2: ' + format('%.2f', @pto2.to_s) + ' %'
    #puts 'PTO4: ' + format('%.2f', @pto4.to_s) + ' %'
    #for i in 0..(@m-1)
    #  puts 'Mesa ' i+1 ': ' + format('%.2f', @pto2[i].to_s)
    #end
    #puts 'PTO4: '
    #for j in 0..(@n-1)
    #  puts 'Mesa ' j+1 ': ' + format('%.2f', @pto4[j].to_s)
    #end
    puts 'PCA: ' + format('%.2f', @pca.to_s)
    puts 'PR24: ' + format('%.2f', @pr24.to_s) + ' %'
    puts 'PS24: ' + format('%.2f', @ps24.to_s) + ' %'
    puts ''
    puts 'Cantidad total de mesas atendidas: '
    puts ''
    puts 'NT2: ' + @nt2.to_s
    puts 'NT4: ' + @nt4.to_s
    puts 'NT6: ' + @nt6.to_s
    puts ''
  end

# Create an instance of the Simulador class
simulador = Simulador.new
# Start the simulation
simulador.simular

end
